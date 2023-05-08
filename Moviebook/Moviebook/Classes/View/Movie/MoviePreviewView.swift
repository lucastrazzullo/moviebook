//
//  MoviePreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MoviePreviewView: View {

    @EnvironmentObject var watchlist: Watchlist

    let details: MovieDetails?
    let onSelected: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: details?.media.posterPreviewUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(details?.title ?? "Loading")
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)

                        if let releaseDate = details?.release {
                            Text(releaseDate, format: .dateTime.year()).font(.caption)
                        }
                    }

                    if let rating = details?.rating {
                        RatingView(rating: rating)
                    }
                }
                .padding(.vertical, 4)
            }
            .onTapGesture(perform: { onSelected?() })

            if let movieId = details?.id {
                Spacer()
                IconWatchlistButton(watchlistItemIdentifier: .movie(id: movieId))
                    .font(.headline)
            }
        }
    }

    init(details: MovieDetails?, onSelected: (() -> Void)? = nil) {
        self.details = details
        self.onSelected = onSelected
    }
}

#if DEBUG
struct MoviePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MoviePreviewViewPreview()
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
                ]))
        }
    }
}

private struct MoviePreviewViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var movie: Movie?

    var body: some View {
        Group {
            if let movie {
                MoviePreviewView(details: movie.details)
                    .padding()
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = MovieWebService(requestManager: requestManager)
            movie = try! await webService.fetchMovie(with: 954)
        }
    }
}
#endif
