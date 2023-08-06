//
//  Navigation.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/04/2023.
//

import SwiftUI
import MoviebookCommon

final class NavigationState: ObservableObject {

    @Published var path: NavigationPath = NavigationPath()
    @Published var presentedItem: NavigationItem? = nil
}

struct Navigation: View {

    @StateObject private var state: NavigationState = NavigationState()

    let rootItem: NavigationItem

    var body: some View {
        NavigationStack(path: $state.path) {
            NavigationDestination(navigationState: state, item: rootItem)
                .navigationDestination(for: NavigationItem.self) { item in
                    NavigationDestination(navigationState: state, item: item)
                }
        }
        .sheet(item: $state.presentedItem) { item in
            Navigation(rootItem: item)
        }
    }
}

private struct NavigationDestination: View {

    @ObservedObject var navigationState: NavigationState

    let item: NavigationItem

    var body: some View {
        switch item {
        case .explore(let selectedGenres):
            ExploreView(
                selectedGenres: selectedGenres,
                presentedItem: $navigationState.presentedItem
            )
        case .movieWithIdentifier(let id):
            MovieView(
                movieId: id,
                navigationPath: $navigationState.path,
                presentedItem: $navigationState.presentedItem
            )
            .id(id)
        case .artistWithIdentifier(let id):
            ArtistView(
                artistId: id,
                navigationPath: $navigationState.path,
                presentedItem: $navigationState.presentedItem
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
                navigationPath: $navigationState.path,
                presentedItem: $navigationState.presentedItem
            )
        }
    }
}
