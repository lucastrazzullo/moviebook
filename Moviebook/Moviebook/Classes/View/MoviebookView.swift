//
//  MoviebookView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct MoviebookView: View {

    enum Tab: Int, Identifiable, CaseIterable {
        case watchlist
        case explore

        var id: Int {
            return self.rawValue
        }

        @ViewBuilder func label() -> some View {
            switch self {
            case .watchlist:
                Label(NSLocalizedString("WATCHLIST.TITLE", comment: ""), systemImage: "star")
            case .explore:
                Label(NSLocalizedString("EXPLORE.TITLE", comment: ""), systemImage: "rectangle.and.text.magnifyingglass")
            }
        }

        @ViewBuilder func view(onStartDiscoverySelected: @escaping () -> Void) -> some View {
            switch self {
            case .watchlist:
                WatchlistView(onStartDiscoverySelected: onStartDiscoverySelected)
            case .explore:
                ExploreView()
            }
        }
    }

    @EnvironmentObject private var watchlist: Watchlist

    @State private var selectedTab: Tab = .watchlist

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases) { tab in
                tab.view(onStartDiscoverySelected: {
                    selectedTab = .explore
                })
                .tag(tab)
                .tabItem(tab.label)
            }
        }
    }
}

struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist())
    }
}
