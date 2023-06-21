//
//  MovieWatchlistStateView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/11/2022.
//

import SwiftUI
import MoviebookCommon

struct MovieWatchlistStateView: View {

    @State private var presentedItem: NavigationItem?
    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieBackdropPreviewUrl: URL?

    var body: some View {
        Group {
            if let state = watchlist.itemState(id: .movie(id: movieId)) {
                switch state {
                case .toWatch(let info):
                    InWatchlistView(presentedItem: $presentedItem, movieId: movieId, info: info)
                case .watched(let info):
                    WatchedView(presentedItem: $presentedItem, movieId: movieId, movieBackdropPreviewUrl: movieBackdropPreviewUrl, info: info)
                }
            } else {
                AddToWatchlistView(movieId: movieId)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.thinMaterial)
        .cornerRadius(24)
        .sheet(item: $presentedItem) { item in
            NavigationDestination(navigationPath: $presentedItemNavigationPath, item: item)
        }
    }
}

private struct WatchedView: View {

    private static let formatter: DateFormatter = {
        let relativeDateFormatter = DateFormatter()
        relativeDateFormatter.timeStyle = .none
        relativeDateFormatter.dateStyle = .medium
        relativeDateFormatter.doesRelativeDateFormatting = true
        return relativeDateFormatter
    }()

    @EnvironmentObject var watchlist: Watchlist

    @Binding var presentedItem: NavigationItem?

    let movieId: Movie.ID
    let movieBackdropPreviewUrl: URL?
    let info: WatchlistItemWatchedInfo

    var body: some View {
        VStack(alignment: .leading, spacing: -12) {
            HStack(alignment: .top, spacing: 8) {
                if let rating = info.rating {
                    CircularRatingView(rating: rating, label: "Your vote", style: .prominent)
                        .frame(height: 150)
                        .padding(.leading, 8)
                } else {
                    Button(action: { presentedItem = .watchlistAddRating(itemIdentifier: .movie(id: movieId)) }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add rating").underline()
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("You watched this movie \(Self.formatter.string(from: info.date).lowercased())")
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)

                    WatermarkWatchlistButton(watchlistItemIdentifier: .movie(id: movieId))
                }
            }
            .foregroundColor(.white)
            .padding()
            .padding(.bottom, info.toWatchInfo.suggestion == nil ? 0 : 12)
            .background(.ultraThinMaterial.opacity(0.6))
            .background(Color.accentColor.opacity(0.2))
            .background(ZStack {
                RemoteImage(
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

            if let suggestion = info.toWatchInfo.suggestion {
                SuggestionView(
                    presentedItem: $presentedItem,
                    movieId: movieId,
                    from: suggestion.owner,
                    comment: suggestion.comment
                )
            }
        }
    }
}

private struct InWatchlistView: View {

    @EnvironmentObject var watchlist: Watchlist

    @Binding var presentedItem: NavigationItem?

    let movieId: Movie.ID
    let info: WatchlistItemToWatchInfo

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: WatchlistViewState.toWatch.icon)
                    Text("In watchlist")
                }
                .font(.title)

                Text("This movie is in your watchlist")
            }
            .padding(.top)

            VStack(spacing: 12) {
                Button(action: { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: info, rating: nil, date: .now)), forItemWith: .movie(id: movieId)) }) {
                    Image(systemName: WatchlistViewState.watched.icon)
                    Text("Mark as watched").font(.headline)
                }
                .buttonStyle(.borderedProminent)

                if let suggestion = info.suggestion {
                    SuggestionView(
                        presentedItem: $presentedItem,
                        movieId: movieId,
                        from: suggestion.owner,
                        comment: suggestion.comment
                    )
                } else {
                    Button(action: { presentedItem = .watchlistAddToWatchReason(itemIdentifier: .movie(id: movieId)) }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add info").underline()
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom)
                }
            }
        }
    }
}

private struct AddToWatchlistView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("Add to your watchlist")
                .font(.headline.bold())

            VStack(spacing: 16) {
                Button(action: { watchlist.update(state: .toWatch(info: .init(date: .now, suggestion: nil)), forItemWith: .movie(id: movieId)) }) {
                    HStack {
                        Image(systemName: WatchlistViewState.toWatch.icon)
                        Text("I want to watch it").font(.headline)
                        Image(systemName: WatchlistViewState.none.icon)
                    }
                    .font(.title)
                }
                .buttonStyle(.borderedProminent)

                Button(action: { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: nil), rating: nil, date: .now)), forItemWith: .movie(id: movieId)) }) {
                    HStack {
                        Image(systemName: WatchlistViewState.watched.icon)
                        Text("I watched it").underline()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

private struct SuggestionView: View {

    @Binding var presentedItem: NavigationItem?

    let movieId: Movie.ID
    let from: String
    let comment: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text("Suggested by \(from)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let comment {
                    Text(comment).font(.body)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { presentedItem = .watchlistAddToWatchReason(itemIdentifier: .movie(id: movieId)) }) {
                Text("Update").font(.footnote)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

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
        .environmentObject(Watchlist(items: []))

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
            WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
            WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
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
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "This is really nice")))),
            WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
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
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: nil), rating: nil, date: .now))),
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
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "This is really nice")), rating: nil, date: .now))),
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
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "This is really nice")), rating: 6, date: .now))),
        ]))
    }
}
