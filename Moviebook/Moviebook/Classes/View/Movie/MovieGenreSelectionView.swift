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
        VStack {
            Text("Genres")
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(genres) { genre in
                        Text(genre.name)
                            .font(.caption.bold())
                            .padding(8)
                            .background(
                                selectedGenres.contains(genre) ? .ultraThinMaterial : .ultraThickMaterial,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .padding(2)
                            .background(Color.secondaryAccentColor, in: RoundedRectangle(cornerRadius: 16))
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
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreHorizontalGenreSection_Previews: PreviewProvider {

    static var previews: some View {
        ScrollView {
            MovieGenreSelectionView(
                selectedGenres: .constant([]),
                genres: [
                    MovieGenre(id: 0, name: "Action"),
                    MovieGenre(id: 1, name: "Adventure"),
                    MovieGenre(id: 2, name: "Anime"),
                    MovieGenre(id: 3, name: "Horror"),
                    MovieGenre(id: 4, name: "Thriller")
                ]
            )
        }
    }
}
#endif
