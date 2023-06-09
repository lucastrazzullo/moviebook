//
//  Navigation.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/04/2023.
//

import SwiftUI
import MoviebookCommons

enum NavigationItem: Identifiable, Hashable {
    case explore
    case movie(_ movie: Movie)
    case movieWithIdentifier(_ id: Movie.ID)
    case artistWithIdentifier(_ id: Artist.ID)
    case watchlistAddToWatchReason(itemIdentifier: WatchlistItemIdentifier)
    case watchlistAddRating(itemIdentifier: WatchlistItemIdentifier)

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
        case .watchlistAddToWatchReason(let item):
            return item.id
        case .watchlistAddRating(let item):
            return item.id
        }
    }
}

struct NavigationDestination: View {

    @Binding var navigationPath: NavigationPath

    let item: NavigationItem

    var body: some View {
        switch item {
        case .explore:
            ExploreView()
        case .movie(let movie):
            MovieView(movie: movie, navigationPath: $navigationPath)
        case .movieWithIdentifier(let id):
            MovieView(movieId: id, navigationPath: $navigationPath)
        case .artistWithIdentifier(let id):
            ArtistView(artistId: id, navigationPath: $navigationPath)
        case .watchlistAddToWatchReason(let itemIdentifier):
            NewToWatchSuggestionView(itemIdentifier: itemIdentifier)
        case .watchlistAddRating(let itemIdentifier):
            NewWatchedRatingView(itemIdentifier: itemIdentifier)
        }
    }
}

struct Navigation: View {

    @Binding var path: NavigationPath

    let presentingItem: NavigationItem

    var body: some View {
        NavigationStack(path: $path) {
            NavigationDestination(navigationPath: $path, item: presentingItem)
                .navigationDestination(for: NavigationItem.self) { item in
                    NavigationDestination(navigationPath: $path, item: item)
                }
        }
    }
}
