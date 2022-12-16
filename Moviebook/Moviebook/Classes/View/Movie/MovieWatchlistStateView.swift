//
//  MovieWatchlistStateView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/11/2022.
//

import SwiftUI

struct MovieWatchlistStateView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieBackdropPreviewUrl: URL?

    var body: some View {
        Group {
            switch watchlist.itemState(item: .movie(id: movieId)) {
            case .none:
                VStack(alignment: .leading, spacing: 8) {
                    Text("You haven't watched this movie.")
                        .font(.headline)

                    Text("If you add it to your watchlist, you can also add a note or you can mark it as watched and add your own vote.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing)

                    Spacer()

                    HStack {
                        Button(action: { watchlist.update(state: .toWatch(reason: .toImplement), for: .movie(id: movieId)) }) {
                            WatchlistLabel(itemState: .none)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { watchlist.update(state: .watched, for: .movie(id: movieId)) }) {
                            WatchlistLabel(itemState: .watched)
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                }

            case .toWatch:
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening").font(.title)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested by Valerio.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("This movie is amazing. Great special effects.")
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.body)
                        }
                        Button(action: { watchlist.update(state: .watched, for: .movie(id: movieId)) }) {
                            WatchlistIcon(itemState: .watched)
                            Text("Mark as watched")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

            case .watched:
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top, spacing: 8) {
                        CircularRatingView(rating: 2.5, label: "Your vote", style: .prominent)
                        .frame(height: 150)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("You watched this movie")
                                .font(.headline)
                                .multilineTextAlignment(.trailing)

                            WatermarkWatchlistButton(watchlistItem: .movie(id: movieId))
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.6))
                    .background(Color.accentColor.opacity(0.2))
                    .background(ZStack {
                        AsyncImage(
                            url: movieBackdropPreviewUrl,
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            },
                            placeholder: { Color.black }
                        )
                        .opacity(0.4)
                    })
                    .background(Color.black)
                    .cornerRadius(12)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening").font(.title)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested by Valerio.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("This movie is amazing. Great special effects.")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(.orange))
    }
}

#if DEBUG
struct MovieWatchlistStateView_Previews: PreviewProvider {
    static var previews: some View {
        MovieWatchlistStateView(
            movieId: 954,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            )
        )
        .padding(24)
        .environmentObject(Watchlist(items: [
            .movie(id: 954): .toWatch(reason: .toImplement)
        ]))
    }
}
#endif
