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

    @Published var movies: [Section.ID: [MovieDetails]] = [:]

    var sections: [Section] {
        return Section.allCases
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

    private func loadMovieDetails(watchlistItems: Set<Watchlist.WatchlistItem>, requestManager: RequestManager) async throws -> [MovieDetails] {
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

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist
    @StateObject private var content: Content = Content()

    var onStartDiscoverySelected: () -> Void = {}

    var body: some View {
        NavigationView {
            Group {
                if watchlist.isEmpty {
                    EmptyWatchlistView(onStartDiscoverySelected: onStartDiscoverySelected)
                } else if content.movies.isEmpty {
                    ProgressView()
                } else {
                    List {
                        ForEach(content.sections) { section in
                            if let movies = content.movies[section.id] {
                                Section(header: Text(section.name)) {
                                    ForEach(movies) { movie in
                                        Text(movie.title)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
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
            .environmentObject(Watchlist())
    }
}
