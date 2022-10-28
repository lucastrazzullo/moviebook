//
//  MovieCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieCardView: View {

    @EnvironmentObject var watchlist: Watchlist

    @State private var watchlistState: Watchlist.WatchlistItemState = .none
    @State private var isOverviewExpanded: Bool = false

    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.details.title).font(.title)
                RatingView(rating: movie.details.rating)
                if let releaseDate = movie.details.release {
                    Text(releaseDate, style: .date).font(.caption)
                }
            }
            .padding(.horizontal)

            Group {
                switch watchlistState {
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
                            Button(action: { watchlist.update(state: .toWatch, for: .movie(id: movie.id)) }) {
                                Text("Add to watchlist")
                            }
                            .buttonStyle(.borderedProminent)

                            Button(action: { watchlist.update(state: .watched, for: .movie(id: movie.id)) }) {
                                Text("Mark as watched")
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
                            Button(action: { watchlist.update(state: .watched, for: .movie(id: movie.id)) }) {
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

                                WatchlistButton(watchlistItem: .movie(id: movie.id)) {
                                    Text("Update").font(.subheadline)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.accentColor.opacity(0.2))
                        .background(.ultraThinMaterial)
                        .background(ZStack {
                            AsyncImage(
                                url: movie.details.media.backdropPreviewUrl,
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.title2)

                Text(movie.overview)
                    .font(.body)
                    .lineLimit(isOverviewExpanded ? nil : 3)

                Button(action: { isOverviewExpanded.toggle() }) {
                    Text(isOverviewExpanded ? "Less" : "More")
                }
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Specs")
                    .font(.title2)
                    .padding(.bottom)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Production").bold()

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("New Line Cinema")
                        Text("Flynn Picture Company")
                        Text("Seven Bucks Productions")
                        Text("DC Films")
                    }
                }

                Divider()

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Budget").bold()
                    Spacer()
                    Text("200.000.000")
                }

                Divider()

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Incassi").bold()
                    Spacer()
                    Text("140.000.000")
                }
            }
            .font(.subheadline)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(.thinMaterial))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .animation(.default, value: isOverviewExpanded)
    }
}

struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MovieCardView(movie: MockServer.movie(with: 616037))
                .environmentObject(Watchlist(moviesToWatch: []))
        }
    }
}
