//
//  ExploreHorizontalMovieGenreSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/07/2023.
//

import SwiftUI
import MoviebookCommon

struct MovieGenreSelectionView: View {

    @Binding var selectedGenres: Set<MovieGenre>

    let genres: [MovieGenre]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(genres) { genre in
                    SwitchButton(
                        isSelected: Binding(
                            get: { selectedGenres.contains(genre) },
                            set: { isSelected in
                                if isSelected {
                                    selectedGenres.insert(genre)
                                } else {
                                    selectedGenres.remove(genre)
                                }
                            }
                        ),
                        label: genre.name
                    )
                    .id(genre.id)
                }
            }
            .padding(.horizontal, 8)
        }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.default, value: selectedGenres)
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreHorizontalGenreSection_Previews: PreviewProvider {

    static var previews: some View {
        MovieGenreSelectionView(
            selectedGenres: .constant([MovieGenre(id: 0, name: "Action")]),
            genres: [
                MovieGenre(id: 0, name: "Action"),
                MovieGenre(id: 1, name: "Adventure"),
                MovieGenre(id: 2, name: "Anime"),
                MovieGenre(id: 3, name: "Horror"),
                MovieGenre(id: 4, name: "Thriller")
            ]
        )
        .preferredColorScheme(.light)
    }
}
#endif
