//
//  WatchlistButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI
import MoviebookCommon

struct WatchlistButton<LabelType>: View where LabelType: View  {

    typealias LabelBuilder = (_ state: WatchlistItemState?, _ shouldShowBadge: String?) -> LabelType

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItemIdentifier: WatchlistItemIdentifier
    let watchlistItemReleaseDate: Date

    @Binding var presentedItem: NavigationItem?
    @ViewBuilder let label: LabelBuilder

    var body: some View {
        Menu {
            WatchlistOptions(
                presentedItem: $presentedItem,
                watchlistItemIdentifier: watchlistItemIdentifier,
                watchlistItemReleaseDate: watchlistItemReleaseDate
            )
        } label: {
            let state = watchlist.itemState(id: watchlistItemIdentifier)
            label(state, shouldShowBadge(state: state))
        }
    }

    private func shouldShowBadge(state: WatchlistItemState?) -> String? {
        guard let state else {
            return nil
        }
        switch state {
        case .toWatch(let info):
            return info.suggestion == nil ? "quote.opening" : nil
        case .watched(let info):
            return info.rating == nil ? "star.fill" : nil
        }
    }
}

struct WatchlistOptions: View {

    @EnvironmentObject var watchlist: Watchlist
    @Binding var presentedItem: NavigationItem?

    let watchlistItemIdentifier: WatchlistItemIdentifier
    let watchlistItemReleaseDate: Date

    var body: some View {
        Group {
            if let state = watchlist.itemState(id: watchlistItemIdentifier) {
                switch state {
                case .toWatch(let info):
                    Button(role: info.suggestion == nil ? .destructive : nil) { presentedItem = .watchlistAddToWatchReason(itemIdentifier: watchlistItemIdentifier) } label: {
                        if info.suggestion == nil {
                            Label("Add reason to watch", systemImage: "quote.opening")
                        } else {
                            Label("Update reason to watch", systemImage: "quote.opening")
                        }
                    }
                    Button { watchlist.remove(itemWith: watchlistItemIdentifier) } label: {
                        Label("Remove from watchlist", systemImage: "minus")
                    }

                    if watchlistItemReleaseDate <= .now {
                        Button { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: info, rating: nil, date: .now)), forItemWith: watchlistItemIdentifier) } label: {
                            Label("Mark as watched", systemImage: "checkmark")
                        }
                    }
                case .watched(let info):
                    Button(role: info.rating == nil ? .destructive : nil) { presentedItem = .watchlistAddRating(itemIdentifier: watchlistItemIdentifier) } label: {
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

                if watchlistItemReleaseDate <= .now {
                    Button { watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: nil), rating: nil, date: .now)), forItemWith: watchlistItemIdentifier) } label: {
                        Label("Mark as watched", systemImage: "checkmark")
                    }
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
                Text(rating, format: .number.precision(.fractionLength(1))).font(.caption2)
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
    let watchlistItemReleaseDate: Date

    @Binding var presentedItem: NavigationItem?

    var body: some View {
        WatchlistButton(
            watchlistItemIdentifier: watchlistItemIdentifier,
            watchlistItemReleaseDate: watchlistItemReleaseDate,
            presentedItem: $presentedItem,
            label: { state, badgeImageName in
            WatchlistIcon(itemState: state)
                .frame(width: 18, height: 18, alignment: .center)
                .ovalStyle(.normal)
                .overlay(alignment: .topTrailing) {
                    if let badgeImageName {
                        Image(systemName: badgeImageName)
                            .foregroundColor(Color.accentColor)
                            .font(.system(size: 10))
                            .frame(width: 8)
                            .padding(6)
                            .background(.ultraThickMaterial, in: Circle())
                            .offset(CGSize(width: 8, height: -8))
                    }
                }
            }
        )
    }
}

#if DEBUG
import MoviebookTestSupport

struct WatchlistButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 44) {
            IconWatchlistButton(
                watchlistItemIdentifier: .movie(id: 954),
                watchlistItemReleaseDate: .now,
                presentedItem: .constant(nil)
            )
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))

            IconWatchlistButton(
                watchlistItemIdentifier: .movie(id: 954),
                watchlistItemReleaseDate: .now,
                presentedItem: .constant(nil)
            )
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true)))

            IconWatchlistButton(
                watchlistItemIdentifier: .movie(id: 954),
                watchlistItemReleaseDate: .now,
                presentedItem: .constant(nil)
            )
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: true, withRating: true)))
        }
        .padding(44)
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}
#endif
