//
//  MoviebookNavigation.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/04/2023.
//

import SwiftUI

enum NavigationItem: Hashable {
    case movie(movieId: Movie.ID)
    case artist(artistId: Artist.ID)
}

struct NavigationDestination: View {

    @Binding var navigationPath: NavigationPath

    let item: NavigationItem

    var body: some View {
        switch item {
        case .movie(let id):
            MovieView(movieId: id, navigationPath: $navigationPath)
        case .artist(let id):
            ArtistView(artistId: id, navigationPath: $navigationPath)
        }
    }
}
