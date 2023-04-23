//
//  MovieCollectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/04/2023.
//

import SwiftUI

struct MovieCollectionView: View {

    let title: String
    let movieDetails: [MovieDetails]
    let highlightedMovieId: Movie.ID?
    let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.title2)
                .padding()
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer()
                        .frame(width: 0)
                        .padding(.leading)
                        .padding(.leading)

                    ForEach(movieDetails) { movieDetails in
                        Group {
                            AsyncImage(url: movieDetails.media.posterPreviewUrl, content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }, placeholder: {
                                Color
                                    .gray
                                    .opacity(0.2)
                            })
                            .frame(width: 80, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(movieDetails.id == highlightedMovieId ? Color.black.opacity(0.6) : Color.clear)
                            )
                        }
                        .onTapGesture {
                            onMovieIdentifierSelected(movieDetails.id)
                        }
                    }

                    Spacer()
                        .frame(width: 0)
                        .padding(.trailing)
                        .padding(.trailing)
                }
                .padding(.bottom)
            }
            .padding(.bottom)
        }
        .background(.ultraThickMaterial)
        .background(.primary)
    }
}

#if DEBUG
struct MovieCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        MovieCollectionView(title: "Movies",
                            movieDetails: MockWebService.movie(with: 954).collection?.list ?? [],
                            highlightedMovieId: 954,
                            onMovieIdentifierSelected: { _ in })
    }
}
#endif
