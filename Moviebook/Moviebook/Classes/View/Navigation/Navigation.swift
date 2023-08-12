//
//  Navigation.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/04/2023.
//

import SwiftUI
import MoviebookCommon

struct Navigation: View {

    @State var navigationPath: NavigationPath = NavigationPath()
    @State var navigationItem: NavigationItem?

    let rootItem: NavigationItem

    var body: some View {
        NavigationStack(path: $navigationPath) {
            NavigationDestination(path: $navigationPath, presentedItem: $navigationItem, item: rootItem)
                .navigationDestination(for: NavigationItem.self) { item in
                    NavigationDestination(path: $navigationPath, presentedItem: $navigationItem, item: item)
                }
        }
        .sheet(item: $navigationItem) { item in
            Navigation(rootItem: item)
        }
    }
}

private struct NavigationDestination: View {

    @Binding var path: NavigationPath
    @Binding var presentedItem: NavigationItem?

    let item: NavigationItem

    var body: some View {
        switch item {
        case .explore(let selectedGenres):
            ExploreView(
                selectedGenres: selectedGenres,
                onItemSelected: { presentedItem = $0 }
            )
        case .movieWithIdentifier(let id):
            MovieView(
                movieId: id,
                navigationPath: $path,
                presentedItem: $presentedItem
            )
            .id(id)
        case .artistWithIdentifier(let id):
            ArtistView(
                artistId: id,
                navigationPath: $path,
                presentedItem: $presentedItem
            )
            .id(id)
        case .watchlistAddToWatchReason(let itemIdentifier):
            NewToWatchSuggestionView(
                itemIdentifier: itemIdentifier
            )
            .id(itemIdentifier.id)
        case .watchlistAddRating(let itemIdentifier):
            NewWatchedRatingView(
                itemIdentifier: itemIdentifier
            )
            .id(itemIdentifier.id)
        case .unratedItems(let items):
            UnratedWatchlistItems(
                items: items,
                navigationPath: $path,
                presentedItem: $presentedItem
            )
        }
    }
}
