//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI
import MoviebookCommon

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
                    Button { presentedItem = .watchlistAddToWatchReason(itemIdentifier: watchlistItemIdentifier) } label: {
                        if info.suggestion == nil {
                            Label("Add reason to watch", systemImage: "quote.opening")
                        } else {
                            Label("Update reason to watch", systemImage: "quote.opening")
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

    var icon: String {
        switch self {
        case .toWatch:
            return "books.vertical.fill"
        case .watched:
            return "person.fill.checkmark"
        case .none:
            return "plus"
        }
    }

    var label: String {
        switch self {
        case .toWatch:
            return "In watchlist"
        case .watched:
            return "Watched"
        case .none:
            return "Add"
        }
    }
}

struct WatchlistIcon: View {

    let itemState: WatchlistItemState?

    var body: some View {
        VStack(alignment: .leading) {
            Image(systemName: WatchlistViewState(itemState: itemState).icon)
            if let itemState, case .watched(let info) = itemState, let rating = info.rating {
                Text(rating, format: .number.precision(.fractionLength(1))).font(.caption)
            }
        }
    }

    init(itemState: WatchlistItemState?) {
        self.itemState = itemState
    }
}

struct WatchlistLabel: View {

    let itemState: WatchlistItemState?

    var body: some View {
        HStack {
            WatchlistIcon(itemState: itemState)
            Text(WatchlistViewState(itemState: itemState).label)
                .fixedSize(horizontal: true, vertical: false)
        }
    }

    init(itemState: WatchlistItemState?) {
        self.itemState = itemState
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
            Text(WatchlistViewState(itemState: state).label)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.black.opacity(0.8))
                .foregroundColor(.white)
                .cornerRadius(8, antialiased: true)
        }
    }
}

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
