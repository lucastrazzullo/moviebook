//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct WatchlistButton<LabelType>: View where LabelType: View  {

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

    @EnvironmentObject var watchlist: Watchlist

    @ViewBuilder let label: (WatchlistContent.ItemState) -> LabelType

    let watchlistItem: WatchlistContent.Item

    var body: some View {
        Menu {
            Button(action: { presentedItem = .addToWatch(item: watchlistItem) }) {
                Label("Add to watchlist", systemImage: "plus")
            }
            .disabled(isAddToWatchlistDisabled)

            Button { presentedItem = .addToWatched(item: watchlistItem) } label: {
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
        .sheet(item: $presentedItem) { item in
            switch item {
            case .addToWatch(let item):
                WatchlistAddToWatchView(item: item)
            case .addToWatched(let item):
                WatchlistAddToWatchedView(item: item)
            }
        }
    }

    init(watchlistItem: WatchlistContent.Item, @ViewBuilder label: @escaping (WatchlistContent.ItemState) -> LabelType) {
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

enum WatchlistViewState {
    case toWatch, watched, none

    init(itemState: WatchlistContent.ItemState) {
        switch itemState {
        case .none:
            self = .none
        case .toWatch:
            self = .toWatch
        case .watched:
            self = .watched
        }
    }
}

struct WatchlistIcon: View {

    let state: WatchlistViewState

    var body: some View {
        switch state {
        case .toWatch:
            Image(systemName: "books.vertical.fill")
        case .watched:
            Image(systemName: "person.fill.checkmark")
        case .none:
            Image(systemName: "plus")
        }
    }

    init(itemState: WatchlistContent.ItemState) {
        self.state = WatchlistViewState(itemState: itemState)
    }

    init(state: WatchlistViewState) {
        self.state = state
    }
}

struct WatchlistText: View {

    let state: WatchlistViewState

    var body: some View {
        switch state {
        case .toWatch:
            Text("In watchlist")
        case .watched:
            Text("Watched")
        case .none:
            Text("Add")
        }
    }

    init(itemState: WatchlistContent.ItemState) {
        self.state = WatchlistViewState(itemState: itemState)
    }

    init(state: WatchlistViewState) {
        self.state = state
    }
}

struct WatchlistLabel: View {

    let state: WatchlistViewState

    var body: some View {
        HStack {
            WatchlistIcon(state: state)
            WatchlistText(state: state)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    init(itemState: WatchlistContent.ItemState) {
        self.state = WatchlistViewState(itemState: itemState)
    }

    init(state: WatchlistViewState) {
        self.state = state
    }
}

// MARK: - Common Buttons

struct IconWatchlistButton: View {

    let watchlistItem: WatchlistContent.Item

    var body: some View {
        WatchlistButton(watchlistItem: watchlistItem) { state in
            WatchlistIcon(itemState: state)
                .padding(8)
        }
    }
}

struct WatermarkWatchlistButton: View {

    let watchlistItem: WatchlistContent.Item

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
                .environmentObject(Watchlist(items: [
                    .movie(id: 954): .toWatch(reason: .none)
                ]))

            WatermarkWatchlistButton(watchlistItem: .movie(id: 954))
                .environmentObject(Watchlist(items: [
                    .movie(id: 954): .watched(reason: .none, rating: 6),
                ]))
        }
    }
}
#endif
