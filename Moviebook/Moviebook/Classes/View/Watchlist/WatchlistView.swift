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

    struct Item: Identifiable {
        var id: Movie.ID {
            return movie.id
        }

        let movie: Movie
    }

    // MARK: Instance Properties

    @Published var items: [Section.ID: [Item]] = [:]
    @Published var error: WebServiceError?

    var sections: [Section] {
        return Section.allCases
    }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Internal methods

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        subscriptions.forEach({ $0.cancel() })

        watchlist.$content
            .map(\.items)
            .sink { [weak self, requestManager] items in
                self?.refreshItems(items, requestManager: requestManager)
            }
            .store(in: &subscriptions)
    }

    func items(forSectionWith identifier: Section.ID) -> [Item] {
        return items[identifier] ?? []
    }

    // MARK: Private helper methods

    private func refreshItems(_ items: [Moviebook.WatchlistContent.Item: Moviebook.WatchlistContent.ItemState], requestManager: RequestManager) {
        var toWatch: [WatchlistContent.Item] = []
        var watched: [WatchlistContent.Item] = []

        items.forEach { item in
            switch item.value {
            case .toWatch:
                toWatch.append(item.key)
            case .watched:
                watched.append(item.key)
            default:
                break
            }
        }

        loadItems(from: toWatch, in: .toWatch, requestManager: requestManager)
        loadItems(from: watched, in: .watched, requestManager: requestManager)
    }

    private func loadItems(from watchlistItems: [WatchlistContent.Item], in section: Section, requestManager: RequestManager) {
        Task { [weak self] in
            do {
                self?.items[section.id] = try await self?.loadItems(watchlistItems: watchlistItems, requestManager: requestManager)
                self?.error = nil
            } catch {
                self?.error = .failedToLoad(id: .init(), retry: { [weak self] in
                    self?.loadItems(from: watchlistItems, in: section, requestManager: requestManager)
                })
            }
        }
    }

    private func loadItems(watchlistItems: [WatchlistContent.Item], requestManager: RequestManager) async throws -> [Item] {
        let movies = try await loadMovies(watchlistItems: watchlistItems, requestManager: requestManager)
        return movies.map(Item.init(movie:))
    }

    private func loadMovies(watchlistItems: [WatchlistContent.Item], requestManager: RequestManager) async throws -> [Movie] {
        return try await watchlistItems
            .compactMap({ self.movieIdentifiers($0) })
            .concurrentMap { movieIdentifier -> Movie in
                let webService = MovieWebService(requestManager: requestManager)
                return try await webService.fetchMovie(with: movieIdentifier)
            }
    }

    private func movieIdentifiers(_ watchlistItem: WatchlistContent.Item) -> Movie.ID? {
        if case .movie(let id) = watchlistItem {
            return id
        } else {
            return nil
        }
    }
}

struct WatchlistView: View {

    enum PresentedItem: Identifiable {
        case movie(Movie)
        case movieWithIdentifier(Movie.ID)

        var id: AnyHashable {
            switch self {
            case .movie(let movie):
                return movie.id
            case .movieWithIdentifier(let id):
                return id
            }
        }
    }

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist
    @StateObject private var content: Content = Content()

    @State private var watchlistNnavigationPath = NavigationPath()
    @State private var presentedItemNavigationPath = NavigationPath()

    @State private var selectedSection: Content.Section = .toWatch
    @State private var isExplorePresented: Bool = false
    @State private var isItemPresented: PresentedItem? = nil
    @State private var isErrorPresented: Bool = false

    var body: some View {
        NavigationStack(path: $watchlistNnavigationPath) {
            List {
                ForEach(content.items(forSectionWith: selectedSection.id)) { item in
                    MoviePreviewView(details: item.movie.details) {
                        isItemPresented = .movie(item.movie)
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
            .navigationDestination(for: Movie.ID.self) { movieId in
                MovieView(movieId: movieId, navigationPath: $watchlistNnavigationPath)
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
                        UISegmentedControl.appearance().backgroundColor = UIColor(Color.black.opacity(0.8))
                        UISegmentedControl.appearance().selectedSegmentTintColor = .white
                        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    WatermarkView {
                        Image(systemName: "magnifyingglass")
                            .onTapGesture {
                                isExplorePresented = true
                            }
                    }
                }
            }
            .sheet(isPresented: $isExplorePresented) {
                ExploreView()
            }
            .sheet(item: $isItemPresented) { item in
                NavigationStack(path: $presentedItemNavigationPath) {
                    Group {
                        switch item {
                        case .movie(let movie):
                            MovieView(movie: movie, navigationPath: $presentedItemNavigationPath)
                        case .movieWithIdentifier(let id):
                            MovieView(movieId: id, navigationPath: $presentedItemNavigationPath)
                        }
                    }
                    .navigationDestination(for: Movie.ID.self) { movieId in
                        MovieView(movieId: movieId, navigationPath: $presentedItemNavigationPath)
                    }
                }
            }
            .alert("Error", isPresented: $isErrorPresented) {
                Button("Retry", role: .cancel) {
                    content.error?.retry()
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
            .environmentObject(Watchlist(items: [
                .movie(id: 954): .toWatch(reason: .toImplement),
                .movie(id: 616037): .toWatch(reason: .toImplement)
            ]))
    }
}
#endif
