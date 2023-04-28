//
//  MovieWatchlistStateView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/11/2022.
//

import SwiftUI

struct MovieWatchlistStateView: View {

    enum PresentedItem: Identifiable {
        case addToWatchReason(item: WatchlistContent.Item)
        case addRating(item: WatchlistContent.Item)

        var id: AnyHashable {
            switch self {
            case .addToWatchReason(let item):
                return item.id
            case .addRating(let item):
                return item.id
            }
        }
    }

    private static let formatter: DateFormatter = {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.doesRelativeDateFormatting = true
        return relativeDateFormatter
    }()

    @State private var presentedItem: PresentedItem?

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieBackdropPreviewUrl: URL?

    var body: some View {
        Group {
            switch watchlist.itemState(item: .movie(id: movieId)) {
            case .none:
                VStack(alignment: .center, spacing: 24) {
                    HStack(alignment: .firstTextBaseline) {
                        WatchlistIcon(state: .toWatch)
                        Text("Watchlist")
                    }
                    .font(.title)

                    VStack(spacing: 16) {
                        Button(action: { watchlist.update(state: .toWatch(reason: .none), for: .movie(id: movieId)) }) {
                            HStack {
                                WatchlistIcon(state: .none)
                                Text("Add to watchlist").font(.headline)
                            }
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { watchlist.update(state: .watched(reason: .none, rating: .none, date: .now), for: .movie(id: movieId)) }) {
                            HStack {
                                WatchlistIcon(state: .watched)
                                Text("Mark as watched").underline()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity)
            case .toWatch(let reason):
                VStack(alignment: .center, spacing: 24) {
                    HStack(alignment: .firstTextBaseline) {
                        WatchlistIcon(state: .toWatch)
                        Text("Watchlist")
                    }
                    .font(.title)

                    Text("This movie is in your watchlist")

                    Button(action: { watchlist.update(state: .watched(reason: reason, rating: .none, date: .now), for: .movie(id: movieId)) }) {
                        WatchlistIcon(state: .watched)
                        Text("Mark as watched").font(.headline)
                    }
                    .buttonStyle(.borderedProminent)

                    switch reason {
                    case .none:
                        Button(action: { presentedItem = .addToWatchReason(item: .movie(id: movieId)) }) {
                            HStack {
                                Image(systemName: "quote.opening")
                                Text("Add suggestion").underline()
                            }
                        }
                        .buttonStyle(.plain)
                    case .suggestion(let from, let comment):
                        SuggestionView(from: from, comment: comment)
                    }
                }
                .frame(maxWidth: .infinity)
            case .watched(let reason, let rating, let date):
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        switch rating {
                        case .value(let value):
                            CircularRatingView(rating: value, label: "Your vote", style: .prominent)
                                .frame(height: 150)
                        case .none:
                            Button(action: { presentedItem = .addRating(item: .movie(id: movieId)) }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Add rating").underline()
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("You watched this movie \(MovieWatchlistStateView.formatter.string(from: date).lowercased())")
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.subheadline)
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

                    switch reason {
                    case .suggestion(let from, let comment):
                        SuggestionView(from: from, comment: comment)
                    case .none:
                        EmptyView()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(.orange))
        .sheet(item: $presentedItem) { item in
            switch item {
            case .addToWatchReason(let item):
                NewToWatchSuggestionView(item: item)
            case .addRating(let item):
                NewWatchedRatingView(item: item)
            }
        }
    }
}

private struct SuggestionView: View {

    let from: String
    let comment: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested by \(from).")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(comment)
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 12).foregroundStyle(.thinMaterial))
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
        .fixedSize(horizontal: false, vertical: true)
        .environmentObject(Watchlist(inMemoryItems: [:]))

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
        .environmentObject(Watchlist(inMemoryItems: [
            .movie(id: 954): .toWatch(reason: .none),
            .movie(id: 616037): .toWatch(reason: .none)
        ]))

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
        .environmentObject(Watchlist(inMemoryItems: [
            .movie(id: 954): .toWatch(reason: .suggestion(from: "Valerio", comment: "This is really nice")),
            .movie(id: 616037): .toWatch(reason: .none)
        ]))

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
        .environmentObject(Watchlist(inMemoryItems: [
            .movie(id: 954): .watched(reason: .suggestion(from: "Valerio", comment: "This is really nice"), rating: .none, date: .now),
        ]))

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
        .environmentObject(Watchlist(inMemoryItems: [
            .movie(id: 954): .watched(reason: .suggestion(from: "Valerio", comment: "This is really nice"), rating: .value(6), date: .now),
        ]))
    }
}
#endif
