//
//  MoviePreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MoviePreviewView: View {

    enum PresentedItem: Identifiable {
        case addToWatch(item: WatchlistContent.Item)
        case addToWatched(item: WatchlistContent.Item)

        var id: AnyHashable {
            switch self {
            case .addToWatch(let item):
                return item.id
            case .addToWatched(let item):
                return item.id
            }
        }
    }

    @State private var presentedItem: PresentedItem?

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
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120)
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
                IconWatchlistButton(watchlistItem: .movie(id: movieId))
                    .font(.headline)
            }
        }
        .sheet(item: $presentedItem) { item in
            switch item {
            case .addToWatch(let item):
                WatchlistAddToWatchView(item: item)
            case .addToWatched(let item):
                WatchlistAddToWatchedView(item: item)
            }
        }
        .contextMenu {
            if let movieId = details?.id {
                WatchlistMenu(
                    watchlistItem: WatchlistContent.Item.movie(id: movieId),
                    shouldAddToWatch: { item in
                        presentedItem = .addToWatch(item: item)
                    },
                    shouldAddToWatched: { item in
                        presentedItem = .addToWatched(item: item)
                    })
            }
        }
    }

    init(details: MovieDetails?, onSelected: (() -> Void)? = nil) {
        self.details = details
        self.onSelected = onSelected
    }
}

private struct WatchlistMenu: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: WatchlistContent.Item
    let shouldAddToWatch: (WatchlistContent.Item) -> Void
    let shouldAddToWatched: (WatchlistContent.Item) -> Void

    var body: some View {
        Group {
            switch watchlist.itemState(item: watchlistItem) {
            case .toWatch:
                Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                    Label("Remove from watchlist", systemImage: "minus")
                }
                Button { shouldAddToWatched(watchlistItem) } label: {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            case .watched:
                Button(action: { shouldAddToWatch(watchlistItem) }) {
                    Label("Move to watchlist", systemImage: "star")
                }
                Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                    Label("Remove from watchlist", systemImage: "minus")
                }
            case .none:
                Button(action: { shouldAddToWatch(watchlistItem) }) {
                    Label("Add to watchlist", systemImage: "plus")
                }
                Button { shouldAddToWatched(watchlistItem) } label: {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            }
        }
    }
}

#if DEBUG
struct MoviePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MoviePreviewViewPreview()
                .environmentObject(Watchlist(items: [
                    .movie(id: 954): .toWatch(reason: .none),
                    .movie(id: 616037): .toWatch(reason: .none)
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
