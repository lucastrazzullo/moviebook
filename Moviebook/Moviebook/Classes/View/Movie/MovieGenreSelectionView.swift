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
                    Text(genre.name)
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundColor(selectedGenres.contains(genre) ? .black : .primary)
                        .background(
                            Color.secondaryAccentColor.opacity(selectedGenres.contains(genre) ? 1 : 0)
                        )
                        .background(.thinMaterial)
                        .cornerRadius(12)
                        .id(genre.id)
                        .onTapGesture {
                            if selectedGenres.contains(genre) {
                                selectedGenres.remove(genre)
                            } else {
                                selectedGenres.insert(genre)
                            }
                        }
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
