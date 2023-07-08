//
//  ExploreHorizontalMovieGenreSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/07/2023.
//

import SwiftUI
import MoviebookCommon
import MoviebookTestSupport

struct ExploreHorizontalMovieGenreSectionView: View {

    @Environment(\.requestManager) var requestManager

    @Binding var selectedGenre: MovieGenre?

    let genres: [MovieGenre]

    var body: some View {
        VStack {
            HeaderView(title: "Genres", isLoading: false)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(genres) { genre in
                        Text(genre.name)
                            .font(.caption.bold())
                            .padding(8)
                            .background(selectedGenre == genre ? .ultraThinMaterial : .ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .padding(2)
                            .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
                            .id(genre.id)
                            .onTapGesture {
                                if let selectedGenre, selectedGenre == genre {
                                    self.selectedGenre = nil
                                } else {
                                    self.selectedGenre = genre
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct HeaderView: View {

    let title: String
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)

            Spacer()

            if isLoading {
                ProgressView()
            }
        }
    }
}

#if DEBUG
struct ExploreHorizontalGenreSection_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ExploreHorizontalMovieGenreSectionView(
                selectedGenre: .constant(MovieGenre(id: 28, name: "Action")),
                genres: [MovieGenre(id: 28, name: "Action"), MovieGenre(id: 12, name: "Adventure")])
        }
    }
}
#endif
