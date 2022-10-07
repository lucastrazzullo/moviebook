//
//  MoviePreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MoviePreviewView: View {

    let details: MovieDetails

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: details.media.backdropPreviewUrl, content: { image in
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
                    Text(details.title)
                        .lineLimit(3)
                        .font(.subheadline)
                        .frame(maxWidth: 140, alignment: .leading)

                    Text("10.10.2018")
                        .font(.caption)

                    RatingView(rating: 3)
                }
                .padding(.vertical, 4)
            }

            WatchlistButton(watchlistItem: Watchlist.WatchlistItem.movie(id: details.id))
                .font(.caption)
        }
        .contextMenu {
            WatchlistMenu(watchlistItem: Watchlist.WatchlistItem.movie(id: details.id))
        }
    }
}

private struct WatchlistMenu: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: Watchlist.WatchlistItem

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
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Move to watchlist", systemImage: "star")
            }
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
        case .none:
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
        }
    }
}

struct MoviePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        MoviePreviewView(details: MockServer.movie(with: 954).details)
            .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
