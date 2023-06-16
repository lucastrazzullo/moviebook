//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI
import MoviebookCommons

struct WatchlistButton<LabelType>: View where LabelType: View  {

    @EnvironmentObject var watchlist: Watchlist

    @State private var presentedItem: NavigationItem?
    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()

    @ViewBuilder let label: (WatchlistItemState?) -> LabelType

    let watchlistItemIdentifier: WatchlistItemIdentifier

    var body: some View {
        Menu {
            WatchlistOptions(
                presentedItem: $presentedItem,
                watchlistItemIdentifier: watchlistItemIdentifier
            )
        } label: {
            label(watchlist.itemState(id: watchlistItemIdentifier))
        }
        .sheet(item: $presentedItem) { item in
            NavigationDestination(navigationPath: $presentedItemNavigationPath, item: item)
        }
    }

    init(watchlistItemIdentifier: WatchlistItemIdentifier, @ViewBuilder label: @escaping (WatchlistItemState?) -> LabelType) {
        self.watchlistItemIdentifier = watchlistItemIdentifier
        self.label = label
    }
}

struct WatchlistOptions: View {

    @EnvironmentObject var watchlist: Watchlist
    @Binding var presentedItem: NavigationItem?

    let watchlistItemIdentifier: WatchlistItemIdentifier

    var body: some View {
        Group {
            if let state = watchlist.itemState(id: watchlistItemIdentifier) {
                switch state {
                case .toWatch(let info):
                    if info.suggestion == nil {
                        Button { presentedItem = .watchlistAddToWatchReason(itemIdentifier: watchlistItemIdentifier) } label: {
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
                    Button { presentedItem = .watchlistAddRating(itemIdentifier: watchlistItemIdentifier) } label: {
                        if info.rating == nil {
                            Label("Add rating", systemImage: "plus")
                        } else {
                            Label("Update rating", systemImage: "star")
                        }
                    }
                    Button { watchlist.update(state: .toWatch(info: info.toWatchInfo), forItemWith: watchlistItemIdentifier) } label: {
                        Label("Move to watchlist", systemImage: "books.vertical.fill")
                    }
                    Button { watchlist.remove(itemWith: watchlistItemIdentifier) } label: {
                        Label("Remove from watchlist", systemImage: "minus")
                    }
                }
            } else {
                Button { watchlist.update(state: .toWatch(info: .init(date: .now, suggestion: nil)), forItemWith: watchlistItemIdentifier) } label: {
                    Label("Add to watchlist", systemImage: "plus")
                }
                Button { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: nil), rating: nil, date: .now)), forItemWith: watchlistItemIdentifier) } label: {
                    Label("Mark as watched", systemImage: "checkmark")
                }
            }
        }
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
            VStack(alignment: .leading) {
                WatchlistIcon(itemState: state)
                if let state, case .watched(let info) = state, let rating = info.rating {
                    Text(rating, format: .number.precision(.fractionLength(1))).font(.caption)
                }
            }
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
    static let toWatchItem = WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil)))
    static let watchedItem = WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: nil), rating: 6.4, date: .now)))
    static var previews: some View {
        VStack(spacing: 44) {
            IconWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: []))

            IconWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: [toWatchItem]))

            IconWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: [watchedItem]))

            WatermarkWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: []))

            WatermarkWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: [toWatchItem]))

            WatermarkWatchlistButton(watchlistItemIdentifier: .movie(id: 954))
                .environmentObject(Watchlist(items: [watchedItem]))
        }
        .padding(44)
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}
#endif
