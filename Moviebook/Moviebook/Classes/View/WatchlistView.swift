//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import Combine

@MainActor private final class Content: ObservableObject {

    // MARK: Types

    enum Section: Identifiable, CaseIterable {
        case toWatch
        case watched

        var id: String {
            return self.name
        }

        var name: String {
            switch self {
            case .toWatch:
                return NSLocalizedString("WATCHLIST.TO_WATCH.TITLE", comment: "")
            case .watched:
                return NSLocalizedString("WATCHLIST.WATCHED.TITLE", comment: "")
            }
        }
    }

    // MARK: Instance Properties

    @Published var selectedSection: Content.Section = .toWatch
    @Published var movies: [Section.ID: [MovieDetails]] = [:]

    var sections: [Section] {
        return Section.allCases
    }

    var movieDetails: [MovieDetails] {
        return movies[selectedSection.id] ?? []
    }

    private var subscriptions: Set<AnyCancellable> = []

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        watchlist.$toWatch.sink { [weak self] watchlistItems in
            Task {
                do {
                    self?.movies[Section.toWatch.id] = try await self?.loadMovieDetails(watchlistItems: watchlistItems, requestManager: requestManager)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
        .store(in: &subscriptions)

        watchlist.$watched.sink { [weak self] watchlistItems in
            Task {
                do {
                    self?.movies[Section.watched.id] = try await self?.loadMovieDetails(watchlistItems: watchlistItems, requestManager: requestManager)
                } catch {
                    assertionFailure(error.localizedDescription)
                }
            }
        }
        .store(in: &subscriptions)
    }

    private func loadMovieDetails(watchlistItems: [Watchlist.WatchlistItem], requestManager: RequestManager) async throws -> [MovieDetails] {
        return try await watchlistItems
            .compactMap({ self.movieIdentifiers($0) })
            .concurrentMap { movieIdentifier -> MovieDetails in
                let webService = MovieWebService(requestManager: requestManager)
                return try await webService.fetchMovie(with: movieIdentifier).details
            }
    }

    private func movieIdentifiers(_ watchlistItem: Watchlist.WatchlistItem) -> Movie.ID? {
        if case .movie(let id) = watchlistItem {
            return id
        } else {
            return nil
        }
    }
}

struct WatchlistView: View {

    enum WatchlistLayout: Equatable {
        case shelf
        case list
    }

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist
    @StateObject private var content: Content = Content()

    @State private var navigationPath = NavigationPath()
    @State private var selectedLayout: WatchlistLayout = .shelf
    @State private var isExplorePresented: Bool = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch selectedLayout {
                case .shelf:
                    ShelfView(
                        movieDetails: content.movieDetails,
                        cornerRadius: isExplorePresented ? 0 : 16,
                        navigationPath: $navigationPath
                    )
                    .padding(.top)
                case .list:
                    List {
                        ForEach(content.movieDetails) { movie in
                            NavigationLink(value: movie.id) {
                                MoviePreviewView(details: movie)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(selectedLayout == .list ? NSLocalizedString("WATCHLIST.TITLE", comment: "") : "")
            .navigationDestination(for: Movie.ID.self) { movieId in
                MovieView(movieId: movieId)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Section", selection: $content.selectedSection) {
                        ForEach(content.sections, id: \.self) { section in
                            Text(section.name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onAppear {
                        switch selectedLayout {
                        case .shelf:
                            UISegmentedControl.appearance().backgroundColor = UIColor(Color.black.opacity(0.7))
                            UISegmentedControl.appearance().selectedSegmentTintColor = .white
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                        case .list:
                            break
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button { isExplorePresented = true } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .buttonStyle(.plain)
                        .frame(width: 32, height: 24)
                        .font(.footnote)

                        Menu {
                            Button { selectedLayout = .shelf } label: {
                                Label("Shelf", systemImage: "square.stack")
                            }
                            Button { selectedLayout = .list } label: {
                                Label("List", systemImage: "list.star")
                            }
                        } label: {
                            Group {
                                switch selectedLayout {
                                case .shelf:
                                    Image(systemName: "square.stack")
                                        .font(.footnote)
                                        .frame(width: 32, height: 24)
                                case .list:
                                    Image(systemName: "list.star")
                                        .font(.footnote)
                                        .frame(width: 32, height: 24)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 0)
                    .background(.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            .sheet(isPresented: $isExplorePresented) {
                NavigationStack {
                    ExploreView()
                        .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
                        .navigationDestination(for: Movie.ID.self) { movieId in
                            MovieView(movieId: movieId)
                        }
                        .toolbar {
                            ToolbarItem {
                                Button(action: { isExplorePresented = false }) {
                                    Text(NSLocalizedString("NAVIGATION.ACTION.CANCEL", comment: ""))
                                }
                            }
                        }
                }
            }
            .task {
                content.start(watchlist: watchlist, requestManager: requestManager)
            }
        }
    }
}

private struct EmptyWatchlistView: View {

    var onStartDiscoverySelected: () -> Void

    var body: some View {
        VStack {
            Text("Your watchlist is empty")
                .font(.headline)

            Button(action: onStartDiscoverySelected) {
                Label("Start your discovery", systemImage: "rectangle.and.text.magnifyingglass")
            }.buttonStyle(.borderedProminent)
        }
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
