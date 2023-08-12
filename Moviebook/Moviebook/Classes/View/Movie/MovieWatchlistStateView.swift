//
//  MovieWatchlistStateView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 05/11/2022.
//

import SwiftUI
import MoviebookCommon

struct MovieWatchlistStateView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieReleaseDate: Date
    let movieBackdropPreviewUrl: URL?

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        Group {
            if let state = watchlist.itemState(id: .movie(id: movieId)) {
                switch state {
                case .toWatch(let info):
                    InWatchlistView(
                        movieId: movieId,
                        movieReleaseDate: movieReleaseDate,
                        info: info,
                        onItemSelected: onItemSelected
                    )
                case .watched(let info):
                    WatchedView(
                        movieId: movieId,
                        movieReleaseDate: movieReleaseDate,
                        movieBackdropPreviewUrl: movieBackdropPreviewUrl,
                        info: info,
                        onItemSelected: onItemSelected
                    )
                }
            } else {
                AddToWatchlistView(
                    movieId: movieId,
                    movieReleaseDate: movieReleaseDate
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .background(.thinMaterial)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

private struct WatchedView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieReleaseDate: Date
    let movieBackdropPreviewUrl: URL?
    let info: WatchlistItemWatchedInfo
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: -12) {
            HStack(alignment: .top, spacing: 8) {
                if let rating = info.rating {
                    CircularRatingView(rating: rating, label: "Your vote", style: .prominent)
                        .frame(height: 150)
                        .padding(.leading, 8)
                } else {
                    Button(action: { onItemSelected(.watchlistAddRating(itemIdentifier: .movie(id: movieId))) }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add rating").underline()
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("You watched this movie")
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.subheadline)
                        .multilineTextAlignment(.trailing)

                    WatchlistButton(
                        watchlistItemIdentifier: .movie(id: movieId),
                        watchlistItemReleaseDate: movieReleaseDate,
                        onItemSelected: onItemSelected) { state, shouldShowBadge in
                        Text(WatchlistViewState(itemState: state).label)
                            .ovalStyle(.normal)
                    }
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
                    movieId: movieId,
                    from: suggestion.owner,
                    comment: suggestion.comment,
                    onItemSelected: onItemSelected
                )
            }
        }
    }
}

private struct InWatchlistView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieReleaseDate: Date
    let info: WatchlistItemToWatchInfo
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            VStack(spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: WatchlistViewState.toWatch.icon)
                    Text("In watchlist".uppercased())
                }
                .font(.heroHeadline)

                Text("This movie is in your watchlist")
            }
            .padding(.top)

            VStack(spacing: 12) {
                if movieReleaseDate <= Date.now {
                    Button(action: { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: info, rating: nil, date: .now)), forItemWith: .movie(id: movieId)) }) {
                        HStack {
                            Image(systemName: WatchlistViewState.watched.icon)
                            Text("Mark as watched")
                        }
                    }
                    .buttonStyle(OvalButtonStyle())
                    .padding(.horizontal)
                }

                if let suggestion = info.suggestion {
                    SuggestionView(
                        movieId: movieId,
                        from: suggestion.owner,
                        comment: suggestion.comment,
                        onItemSelected: onItemSelected
                    )
                } else {
                    Button(action: { onItemSelected(.watchlistAddToWatchReason(itemIdentifier: .movie(id: movieId))) }) {
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
    let movieReleaseDate: Date

    var body: some View {
        VStack(alignment: .center, spacing: 24) {
            Text("Add to your watchlist".uppercased())
                .font(.heroHeadline)
                .padding(.top, 8)

            VStack(spacing: 16) {
                Button(action: { watchlist.update(state: .toWatch(info: .init(date: .now, suggestion: nil)), forItemWith: .movie(id: movieId)) }) {
                    HStack {
                        Image(systemName: WatchlistViewState.toWatch.icon)
                        Text("I want to watch it").font(.headline)
                        Image(systemName: WatchlistViewState.none.icon)
                    }
                }
                .buttonStyle(OvalButtonStyle())

                if movieReleaseDate <= Date.now {
                    Button(action: { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: nil), rating: nil, date: .now)), forItemWith: .movie(id: movieId)) }) {
                        HStack {
                            Image(systemName: WatchlistViewState.watched.icon)
                            Text("I watched it").underline()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
    }
}

private struct SuggestionView: View {

    let movieId: Movie.ID
    let from: String?
    let comment: String?
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "quote.opening")
                .font(.title2)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                if let from, !from.isEmpty {
                    Text("Suggested by \(from)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if let comment, !comment.isEmpty {
                    Text(comment)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: { onItemSelected(.watchlistAddToWatchReason(itemIdentifier: .movie(id: movieId))) }) {
                Text("Update").font(.footnote)
            }
            .buttonStyle(OvalButtonStyle(.small))
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

#if DEBUG
import MoviebookTestSupport
import TheMovieDb

struct MovieWatchlistStateView_Previews: PreviewProvider {
    static var previews: some View {
        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .fixedSize(horizontal: false, vertical: true)
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now.addingTimeInterval(100000000),
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .fixedSize(horizontal: false, vertical: true)
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: false)))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now.addingTimeInterval(100000000),
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: false)))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true)))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now.addingTimeInterval(1000000000),
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true)))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: false, withRating: false)))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: true, withRating: false)))

        MovieWatchlistStateView(
            movieId: 954,
            movieReleaseDate: .now,
            movieBackdropPreviewUrl: try? TheMovieDbImageRequestFactory.makeURL(
                format: .backdrop(
                    path: "/eDtsTxALld2gPw9lO1hQIJXqMHu.jpg",
                    size: .preview
                )
            ),
            onItemSelected: { _ in }
        )
        .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: true, withRating: true)))
    }
}
#endif
