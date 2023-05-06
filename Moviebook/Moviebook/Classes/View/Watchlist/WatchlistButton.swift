//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct WatchlistButton<LabelType>: View where LabelType: View  {

    enum PresentedItem: Identifiable {
        case addToWatchReason(itemIdentifier: WatchlistItemIdentifier)
        case addRating(itemIdentifier: WatchlistItemIdentifier)

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

    @ViewBuilder let label: (WatchlistItemState?) -> LabelType

    let watchlistItemIdentifier: WatchlistItemIdentifier

    var body: some View {
        Menu {
            if let state = watchlist.itemState(id: watchlistItemIdentifier) {
                switch state {
                case .toWatch(let info):
                    if info.suggestion == nil {
                        Button { presentedItem = .addToWatchReason(itemIdentifier: watchlistItemIdentifier) } label: {
                            Label("Add reason to watch", systemImage: "quote.opening")
                        }
                    }
                    Button { watchlist.remove(itemWith: watchlistItemIdentifier) } label: {
                        Label("Remove from watchlist", systemImage: "minus")
                    }
                    Button { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: info, rating: nil, date: .now)), forItemWith: watchlistItemIdentifier) } label: {
                        Label("Mark as watched", systemImage: "checkmark")
                    }
                case .watched(let info):
                    if info.rating == nil {
                        Button { presentedItem = .addRating(itemIdentifier: watchlistItemIdentifier) } label: {
                            Label("Add rating", systemImage: "plus")
                        }
                    }
                    Button { watchlist.update(state: .toWatch(info: info.toWatchInfo), forItemWith: watchlistItemIdentifier) } label: {
                        Label("Move to watchlist", systemImage: "star")
                    }
                    Button { watchlist.remove(itemWith: watchlistItemIdentifier) } label: {
                        Label("Remove from watchlist", systemImage: "minus")
                    }
                }
            } else {
                Button { watchlist.update(state: .toWatch(info: .init(suggestion: nil)), forItemWith: watchlistItemIdentifier) } label: {
                    Label("Add to watchlist", systemImage: "plus")
                }
                Button { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(suggestion: nil), rating: nil, date: .now)), forItemWith: watchlistItemIdentifier) } label: {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            }
        } label: {
            label(watchlist.itemState(id: watchlistItemIdentifier))
        }
        .sheet(item: $presentedItem) { item in
            switch item {
            case .addToWatchReason(let itemIdentifier):
                NewToWatchSuggestionView(itemIdentifier: itemIdentifier)
            case .addRating(let itemIdentifier):
                NewWatchedRatingView(itemIdentifier: itemIdentifier)
            }
        }
    }

    init(watchlistItemIdentifier: WatchlistItemIdentifier, @ViewBuilder label: @escaping (WatchlistItemState?) -> LabelType) {
        self.watchlistItemIdentifier = watchlistItemIdentifier
        self.label = label
    }
}

// MARK: - Common Views

enum WatchlistViewState {
    case toWatch, watched, none

    init(itemState: WatchlistItemState?) {
        guard let itemState else {
            self = .none
            return
        }
        switch itemState {
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

    init(itemState: WatchlistItemState?) {
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

    init(itemState: WatchlistItemState) {
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

    init(itemState: WatchlistItemState?) {
        self.state = WatchlistViewState(itemState: itemState)
    }

    init(state: WatchlistViewState) {
        self.state = state
    }
}

// MARK: - Common Buttons

struct IconWatchlistButton: View {

    let watchlistItemIdentifier: WatchlistItemIdentifier

    var body: some View {
        WatchlistButton(watchlistItemIdentifier: watchlistItemIdentifier) { state in
            WatchlistIcon(itemState: state)
                .padding(8)
        }
    }
}

struct WatermarkWatchlistButton: View {

    let watchlistItemIdentifier: WatchlistItemIdentifier

    var body: some View {
        WatchlistButton(watchlistItemIdentifier: watchlistItemIdentifier) { state in
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
            IconWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(suggestion: nil)))
                ]))

            WatermarkWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(suggestion: nil), rating: 6, date: .now)))
                ]))
        }
    }
}
#endif
