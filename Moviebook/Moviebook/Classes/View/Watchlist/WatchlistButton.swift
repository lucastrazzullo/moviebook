//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct WatchlistButton<LabelType>: View where LabelType: View  {

    @EnvironmentObject var watchlist: Watchlist

    @ViewBuilder let label: (Watchlist.WatchlistItemState) -> LabelType

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        Menu {
            Button { watchlist.update(state: .toWatch(reason: .toImplement), for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            .disabled(isAddToWatchlistDisabled)

            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
            .disabled(isMarkAsWatchedDisabled)

            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
            .disabled(isRemoveFromWatchlistDisabled)

        } label: {
            label(watchlist.itemState(item: watchlistItem))
        }
    }

    init(watchlistItem: Watchlist.WatchlistItem, @ViewBuilder label: @escaping (Watchlist.WatchlistItemState) -> LabelType) {
        self.watchlistItem = watchlistItem
        self.label = label
    }

    // MARK: Private helper methods

    private var isAddToWatchlistDisabled: Bool {
        guard case .toWatch = watchlist.itemState(item: watchlistItem) else {
            return false
        }
        return true
    }

    private var isMarkAsWatchedDisabled: Bool {
        guard case .watched = watchlist.itemState(item: watchlistItem) else {
            return false
        }
        return true
    }

    private var isRemoveFromWatchlistDisabled: Bool {
        guard case .none = watchlist.itemState(item: watchlistItem) else {
            return false
        }
        return true
    }
}

// MARK: - Common Views

struct WatchlistIcon: View {

    let itemState: Watchlist.WatchlistItemState

    var body: some View {
        switch itemState {
        case .toWatch:
            Image(systemName: "books.vertical.fill")
        case .watched:
            Image(systemName: "person.fill.checkmark")
        case .none:
            Image(systemName: "plus")
        }
    }
}

struct WatchlistText: View {

    let itemState: Watchlist.WatchlistItemState

    var body: some View {
        switch itemState {
        case .toWatch:
            Text("In watchlist")
        case .watched:
            Text("Watched")
        case .none:
            Text("Add")
        }
    }
}

struct WatchlistLabel: View {

    let itemState: Watchlist.WatchlistItemState

    var body: some View {
        HStack {
            WatchlistIcon(itemState: itemState)
            WatchlistText(itemState: itemState)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - Common Buttons

struct IconWatchlistButton: View {

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        WatchlistButton(watchlistItem: watchlistItem) { state in
            WatchlistIcon(itemState: state)
                .padding(8)
        }
    }
}

struct WatermarkWatchlistButton: View {

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        WatchlistButton(watchlistItem: watchlistItem) { state in
            WatermarkView {
                WatchlistLabel(itemState: state)
            }
        }
    }
}

#if DEBUG
struct WatchlistButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 44) {
            IconWatchlistButton(watchlistItem: .movie(id: 954))
                .environmentObject(Watchlist(moviesToWatch: [954]))

            WatermarkWatchlistButton(watchlistItem: .movie(id: 954))
                .environmentObject(Watchlist(watchedMovies: [954]))
        }
    }
}
#endif
