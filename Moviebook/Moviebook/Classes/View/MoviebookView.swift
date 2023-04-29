//
//  MoviebookView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct MoviebookView: View {

    enum PresentedItem: Identifiable {
        case explore(query: String?)
        case movie(_ movie: Movie)
        case movieWithIdentifier(_ id: Movie.ID)
        case artistWithIdentifier(_ id: Artist.ID)

        var id: AnyHashable {
            switch self {
            case .explore:
                return "Explore"
            case .movie(let movie):
                return movie.id
            case .movieWithIdentifier(let id):
                return id
            case .artistWithIdentifier(let id):
                return id
            }
        }
    }

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: PresentedItem? = nil

    var body: some View {
        NavigationView {
            WatchlistView(onExploreSelected: {
                presentedItem = .explore(query: nil)
            }, onMovieSelected: { movie in
                presentedItem = .movie(movie)
            })
        }
        .onOpenURL { url in
            if let deeplink = Deeplink(rawValue: url) {
                switch deeplink {
                case .watchlist:
                    presentedItem = nil
                case .search(let query):
                    presentedItem = .explore(query: query)
                case .movie(let identifier):
                    presentedItem = .movieWithIdentifier(identifier)
                case .artist(let identifier):
                    presentedItem = .artistWithIdentifier(identifier)
                }
            }
        }
        .sheet(item: $presentedItem) { item in
            NavigationStack(path: $presentedItemNavigationPath) {
                Group {
                    switch item {
                    case .explore(let query):
                        ExploreView(searchQuery: query)
                    case .movie(let movie):
                        MovieView(movie: movie, navigationPath: $presentedItemNavigationPath)
                    case .movieWithIdentifier(let id):
                        MovieView(movieId: id, navigationPath: $presentedItemNavigationPath)
                    case .artistWithIdentifier(let id):
                        ArtistView(artistId: id, navigationPath: $presentedItemNavigationPath)
                    }
                }
                .navigationDestination(for: NavigationItem.self) { item in
                    NavigationDestination(navigationPath: $presentedItemNavigationPath, item: item)
                }
            }
        }
    }
}

#if DEBUG
struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(inMemoryItems: [
                .movie(id: 954): .toWatch(reason: .none),
                .movie(id: 616037): .toWatch(reason: .none)
            ]))
    }
}
#endif
