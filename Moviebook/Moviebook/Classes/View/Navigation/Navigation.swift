//
//  Navigation.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/04/2023.
//

import SwiftUI
import MoviebookCommon

struct Navigation: View {

    @State private var path: NavigationPath = NavigationPath()

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

private struct NavigationDestination: View {

    @Binding var navigationPath: NavigationPath

    let item: NavigationItem

    var body: some View {
        switch item {
        case .explore:
            ExploreView()
        case .movieWithIdentifier(let id):
            MovieView(movieId: id, navigationPath: $navigationPath).id(id)
        case .artistWithIdentifier(let id):
            ArtistView(artistId: id, navigationPath: $navigationPath).id(id)
        case .watchlistAddToWatchReason(let itemIdentifier):
            NewToWatchSuggestionView(itemIdentifier: itemIdentifier).id(itemIdentifier.id)
        case .watchlistAddRating(let itemIdentifier):
            NewWatchedRatingView(itemIdentifier: itemIdentifier).id(itemIdentifier.id)
        }
    }
}
