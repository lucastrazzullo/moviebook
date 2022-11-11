//
//  MovieCollectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 06/11/2022.
//

import SwiftUI

struct MovieCollectionView: View {

    let name: String
    let movieDetails: [MovieDetails]
    let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Belong to:")
            Text(name).font(.title2)

            ScrollView(.horizontal) {
                HStack {
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
                            .frame(height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(.trailing, 4)
                        .padding(.bottom, 4)
                        .onTapGesture {
                            onMovieIdentifierSelected(movieDetails.id)
                        }
                    }
                }
                .padding(.vertical)
            }
        }
    }
}

struct MovieCollectionView_Previews: PreviewProvider {
    static let collections: [MovieCollection] = {
        return [
            MockWebService.movie(with: 954).collection!,
            MockWebService.movie(with: 616037).collection!
        ]
    }()

    static var previews: some View {
        Group {
            ForEach(collections) { collection in
                MovieCollectionView(
                    name: collection.name,
                    movieDetails: collection.list!,
                    onMovieIdentifierSelected: { _ in }
                )
            }
        }
    }
}
