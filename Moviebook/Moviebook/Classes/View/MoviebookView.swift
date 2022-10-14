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

        var icon: Image {
            switch self {
            case .watchlist:
                return Image(systemName: "star")
            case .explore:
                return Image(systemName: "rectangle.and.text.magnifyingglass")
            }
        }

        @ViewBuilder func label() -> some View {
            switch self {
            case .watchlist:
                Label(NSLocalizedString("WATCHLIST.TITLE", comment: ""), systemImage: "star")
            case .explore:
                Label(NSLocalizedString("EXPLORE.TITLE", comment: ""), systemImage: "rectangle.and.text.magnifyingglass")
            }
        }
    }

    @EnvironmentObject private var watchlist: Watchlist

    @State private var selectedTab: Tab = .watchlist

    var body: some View {
//        ZStack(alignment: .bottom) {
//            Group {
//                switch selectedTab {
//                case .watchlist:
//                    WatchlistView()
//                case .explore:
//                    ExploreView()
//                }
//            }
//
//            TabSelector(
//                selectedTab: Binding(
//                    get: { .init(id: selectedTab.id, icon: selectedTab.icon)},
//                    set: { tab in if let tab = Tab(rawValue: tab.id) { selectedTab = tab }}
//                ),
//                tabs: Tab.allCases
//                    .map({ tab in .init(id: tab.id, icon: tab.icon) })
//            )
//        }
        WatchlistView()
    }
}

// MARK: Tab Selector

private struct TabSelector: View {

    struct Tab: Identifiable, Equatable {
        let id: Int
        let icon: Image
    }

    private static let itemSize: CGFloat = 44
    private static let borderSize: CGFloat = 3

    @Binding var selectedTab: Tab

    let tabs: [Tab]

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .selectedItem, vertical: .center)) {
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color(UIColor.systemBackground))
                .frame(width: Self.itemSize, height: Self.itemSize)
                .opacity(tabs.contains(selectedTab) ? 1 : 0)

            HStack {
                ForEach(tabs, id: \.id) { tab in
                    tab.icon
                        .foregroundColor(tab == selectedTab ?.primary : Color(UIColor.systemBackground))
                        .frame(width: Self.itemSize, height: Self.itemSize)
                        .alignmentGuide(tab == selectedTab ? .selectedItem : .center) {
                            dimensions in dimensions[HorizontalAlignment.center]
                        }
                        .onTapGesture(perform: { selectedTab = tab })
                }
            }
        }
        .padding(Self.borderSize)
        .background(.primary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .font(.headline)
        .animation(.default, value: selectedTab)
    }
}

private extension HorizontalAlignment {

    struct SelectedItemAlignment: AlignmentID {
        static func defaultValue(in d: ViewDimensions) -> CGFloat {
            d[HorizontalAlignment.center]
        }
    }

    static let selectedItem = HorizontalAlignment(SelectedItemAlignment.self)
}

struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
