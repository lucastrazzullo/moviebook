//
//  MoviePreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MoviePreviewView: View {

    let details: MovieDetails?
    let onSelected: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: details?.media.backdropPreviewUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .frame(width: 160, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(details?.title ?? "Loading")
                        .lineLimit(3)
                        .font(.subheadline)
                        .frame(maxWidth: 140, alignment: .leading)

                    if let releaseDate = details?.release {
                        Text(releaseDate, format: .dateTime.year()).font(.caption)
                    }

                    if let rating = details?.rating {
                        RatingView(rating: rating)
                    }
                }
                .padding(.vertical, 4)
            }
            .onTapGesture(perform: { onSelected?() })

            if let movieId = details?.id {
                IconWatchlistButton(watchlistItem: .movie(id: movieId))
                    .font(.caption)
            }
        }
        .contextMenu {
            if let movieId = details?.id {
                WatchlistMenu(watchlistItem: WatchlistContent.Item.movie(id: movieId))
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

    var body: some View {
        switch watchlist.itemState(item: watchlistItem) {
        case .toWatch:
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
        case .watched:
            Button { watchlist.update(state: .toWatch(reason: .toImplement), for: watchlistItem) } label: {
                Label("Move to watchlist", systemImage: "star")
            }
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
        case .none:
            Button { watchlist.update(state: .toWatch(reason: .toImplement), for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
        }
    }
}

#if DEBUG
struct MoviePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        MoviePreviewView(details: MockWebService.movie(with: 954).details)
            .environmentObject(Watchlist(items: [
                .movie(id: 954): .toWatch(reason: .toImplement),
                .movie(id: 616037): .toWatch(reason: .toImplement)
            ]))
    }
}
#endif
