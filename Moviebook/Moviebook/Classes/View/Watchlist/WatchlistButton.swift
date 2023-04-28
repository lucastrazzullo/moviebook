//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct WatchlistButton<LabelType>: View where LabelType: View  {

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

    @EnvironmentObject var watchlist: Watchlist

    @State private var presentedItem: PresentedItem?

    @ViewBuilder let label: (WatchlistContent.ItemState) -> LabelType

    let watchlistItem: WatchlistContent.Item

    var body: some View {
        Menu {
            switch watchlist.itemState(item: watchlistItem) {
            case .toWatch(let reason):
                if reason == .none {
                    Button { presentedItem = .addToWatchReason(item: watchlistItem) } label: {
                        Label("Add reason to watch", systemImage: "quote.opening")
                    }
                }
                Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                    Label("Remove from watchlist", systemImage: "minus")
                }
                Button { watchlist.update(state: .watched(reason: reason, rating: .none, date: .now), for: watchlistItem) } label: {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            case .watched(let reason, let rating, _):
                if rating == .none {
                    Button { presentedItem = .addRating(item: watchlistItem) } label: {
                        Label("Add rating", systemImage: "plus")
                    }
                }
                Button(action: { watchlist.update(state: .toWatch(reason: reason), for: watchlistItem) }) {
                    Label("Move to watchlist", systemImage: "star")
                }
                Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                    Label("Remove from watchlist", systemImage: "minus")
                }
            case .none:
                Button(action: { watchlist.update(state: .toWatch(reason: .none), for: watchlistItem) }) {
                    Label("Add to watchlist", systemImage: "plus")
                }
                Button { watchlist.update(state: .watched(reason: .none, rating: .none, date: .now), for: watchlistItem) } label: {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            }

        } label: {
            label(watchlist.itemState(item: watchlistItem))
        }
        .sheet(item: $presentedItem) { item in
            switch item {
            case .addToWatchReason(let item):
                NewToWatchSuggestionView(item: item)
            case .addRating(let item):
                NewWatchedRatingView(item: item)
            }
        }
    }

    init(watchlistItem: WatchlistContent.Item, @ViewBuilder label: @escaping (WatchlistContent.ItemState) -> LabelType) {
        self.watchlistItem = watchlistItem
        self.label = label
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
            WatchlistLabel(itemState: state)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8, antialiased: true)
        }
    }
}

#if DEBUG
struct WatchlistButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 44) {
            IconWatchlistButton(watchlistItem: .movie(id: 954))
                .environmentObject(Watchlist(inMemoryItems: [
                    .movie(id: 954): .toWatch(reason: .none)
                ]))

            WatermarkWatchlistButton(watchlistItem: .movie(id: 954))
                .environmentObject(Watchlist(inMemoryItems: [
                    .movie(id: 954): .watched(reason: .none, rating: .value(6), date: .now),
                ]))
        }
    }
}
#endif
