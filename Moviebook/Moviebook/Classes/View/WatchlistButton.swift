//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct WatchlistButton: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        Menu {
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            .disabled(watchlist.itemState(item: watchlistItem) == .toWatch)

            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
            .disabled(watchlist.itemState(item: watchlistItem) == .watched)

            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
            .disabled(watchlist.itemState(item: watchlistItem) == .none)

        } label: {
            switch watchlist.itemState(item: watchlistItem) {
            case .toWatch:
                Image(systemName: "star")
            case .watched:
                Image(systemName: "checkmark")
            case .none:
                Image(systemName: "plus")
            }
        }
    }
}

struct WatchlistButton_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistButton(watchlistItem: .movie(id: 954))
            .environmentObject(Watchlist(moviesToWatch: [954]))
    }
}
