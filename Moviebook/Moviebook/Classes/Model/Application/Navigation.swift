//
//  Navigation.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/04/2023.
//

import SwiftUI

enum NavigationItem: Identifiable, Hashable {
    case explore
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