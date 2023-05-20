//
//  MoviebookView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import CoreSpotlight

struct MoviebookView: View {

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        NavigationView {
            WatchlistView(onExploreSelected: {
                presentedItem = .explore
            }, onMovieSelected: { movie in
                presentedItem = .movie(movie)
            })
        }
        .onOpenURL { url in
            if let deeplink = Deeplink(rawValue: url) {
                open(deeplink: deeplink)
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            if let deeplink = Spotlight.deeplink(from: userActivity) {
                open(deeplink: deeplink)
            }
        }
        .sheet(item: $presentedItem) { item in
            Navigation(path: $presentedItemNavigationPath, presentingItem: item)
        }
    }

    // MARK: Private helper methods

    private func open(deeplink: Deeplink) {
        switch deeplink {
        case .watchlist:
            presentedItem = nil
        case .movie(let identifier):
            presentedItem = .movieWithIdentifier(identifier)
        case .artist(let identifier):
            presentedItem = .artistWithIdentifier(identifier)
        }
    }
}

#if DEBUG
struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))
    }
}
#endif
