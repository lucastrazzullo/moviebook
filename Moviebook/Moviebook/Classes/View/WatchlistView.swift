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

    enum Error: Swift.Error, Equatable {
        case failedToLoad
    }

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

    struct Item: Identifiable {
        var id: Movie.ID {
            return movie.id
        }

        let movie: Movie
    }

    // MARK: Instance Properties

    @Published var items: [Section.ID: [Item]] = [:]
    @Published var error: Error?

    var sections: [Section] {
        return Section.allCases
    }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        watchlist.$toWatch.sink { [weak self] watchlistItems in
            Task {
                do {
                    self?.items[Section.toWatch.id] = try await self?.loadItems(watchlistItems: watchlistItems, requestManager: requestManager)
                    self?.error = nil
                } catch {
                    self?.error = .failedToLoad
                }
            }
        }
        .store(in: &subscriptions)

        watchlist.$watched.sink { [weak self] watchlistItems in
            Task {
                do {
                    self?.items[Section.watched.id] = try await self?.loadItems(watchlistItems: watchlistItems, requestManager: requestManager)
                    self?.error = nil
                } catch {
                    self?.error = .failedToLoad
                }
            }
        }
        .store(in: &subscriptions)
    }

    func items(forSectionWith identifier: Section.ID) -> [Item] {
        return items[identifier] ?? []
    }

    // MARK: Private helper methods

    private func loadItems(watchlistItems: [Watchlist.WatchlistItem], requestManager: RequestManager) async throws -> [Item] {
        let movies = try await loadMovies(watchlistItems: watchlistItems, requestManager: requestManager)
        return movies.map(Item.init(movie:))
    }

    private func loadMovies(watchlistItems: [Watchlist.WatchlistItem], requestManager: RequestManager) async throws -> [Movie] {
        return try await watchlistItems
            .compactMap({ self.movieIdentifiers($0) })
            .concurrentMap { movieIdentifier -> Movie in
                let webService = MovieWebService(requestManager: requestManager)
                return try await webService.fetchMovie(with: movieIdentifier)
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

    @State private var watchlistNavigationPath = NavigationPath()
    @State private var exploreNavigationPath = NavigationPath()
    @State private var selectedLayout: WatchlistLayout = .shelf
    @State private var selectedSection: Content.Section = .toWatch
    @State private var isExplorePresented: Bool = false
    @State private var isMoviePresented: Movie? = nil
    @State private var isErrorPresented: Bool = false

    var body: some View {
        NavigationStack(path: $watchlistNavigationPath) {
            ZStack {
                switch selectedLayout {
                case .shelf:
                    ShelfView(
                        items: content.items(forSectionWith: selectedSection.id)
                            .map(\.movie)
                            .map(ShelfView.ShelfItem.init(movie:)),
                        cornerRadius: isExplorePresented ? 0 : 16,
                        onOpen: { item in
                            isMoviePresented = item.movie
                        }
                    )
                    .id(selectedSection.id)
                    .padding(.top)
                case .list:
                    List {
                        ForEach(content.items(forSectionWith: selectedSection.id)) { item in
                            NavigationLink(value: item.id) {
                                MoviePreviewView(details: item.movie.details)
                            }
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(selectedLayout == .list ? NSLocalizedString("WATCHLIST.TITLE", comment: "") : "")
            .navigationDestination(for: Movie.ID.self) { movieId in
                MovieView(movieId: movieId, navigationPath: $watchlistNavigationPath)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(content.sections, id: \.self) { section in
                            Text(section.name)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onAppear {
                        switch selectedLayout {
                        case .shelf:
                            UISegmentedControl.appearance().backgroundColor = UIColor(Color.black.opacity(0.8))
                            UISegmentedControl.appearance().selectedSegmentTintColor = .white
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                            UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                        case .list:
                            break
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    WatermarkView {
                        Image(systemName: "magnifyingglass")
                            .onTapGesture {
                                isExplorePresented = true
                            }

                        Menu {
                            Button { selectedLayout = .shelf } label: {
                                Label("Shelf", systemImage: "square.stack")
                            }
                            Button { selectedLayout = .list } label: {
                                Label("List", systemImage: "list.star")
                            }
                        } label: {
                            switch selectedLayout {
                            case .shelf:
                                Image(systemName: "square.stack")
                            case .list:
                                Image(systemName: "list.star")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $isExplorePresented) {
                NavigationStack(path: $exploreNavigationPath) {
                    ExploreView()
                        .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
                        .navigationDestination(for: Movie.ID.self) { movieId in
                            MovieView(movieId: movieId, navigationPath: $exploreNavigationPath)
                        }
                        .toolbar {
                            ToolbarItem {
                                Button(action: { isExplorePresented = false }) {
                                    Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                                }
                            }
                        }
                }
            }
            .sheet(item: $isMoviePresented) { movie in
                MovieView(movie: movie, navigationPath: nil)
            }
            .alert("Error", isPresented: $isErrorPresented) {
                Button("Retry", role: .cancel) {
                    content.start(watchlist: watchlist, requestManager: requestManager)
                }
            }
            .onChange(of: content.error) { error in
                isErrorPresented = error != nil
            }
            .onAppear {
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

#if DEBUG
struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
#endif
