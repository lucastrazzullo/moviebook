//
//  MovieCollectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 06/11/2022.
//

import SwiftUI

struct MovieCollectionView: View {

    let collection: MovieCollection

    let onMovieIdentifierSelected: (Movie.ID) -> Void
    let onCollectionIdentifierSelected: (MovieCollection.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Belong to:")
            Text(collection.name).font(.title2)

            if let list = collection.list, !list.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(list) { movieDetails in
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
            } else {
                Button(action: { onCollectionIdentifierSelected(collection.id) }) {
                    Text("Open")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct MovieCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MovieCollectionView(
                collection: MockWebService.movie(with: 954).collection!,
                onMovieIdentifierSelected: { _ in },
                onCollectionIdentifierSelected: { _ in }
            )
            MovieCollectionView(
                collection: MockWebService.movie(with: 616037).collection!,
                onMovieIdentifierSelected: { _ in },
                onCollectionIdentifierSelected: { _ in }
            )
        }
    }
}
