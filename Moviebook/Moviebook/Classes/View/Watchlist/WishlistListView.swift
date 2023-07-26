//
//  WishlistListView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import SwiftUI

struct WishlistListView: View {

    @AppStorage("wishlistSorting") private var internalSorting: WatchlistViewSorting = .lastAdded
    @State private var isPresented: Bool = false

    @Binding var sorting: WatchlistViewSorting

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(spacing: 4), GridItem()], spacing: 4) {
            ForEach(items.sorted(by: sort(sorting: sorting))) { item in
                switch item {
                case .movie(let movie, _):
                    MovieShelfPreviewView(
                        movieDetails: movie.details,
                        onItemSelected: onItemSelected
                    )
                }
            }
        }
        .padding(.horizontal, 4)
        .onAppear {
            isPresented = true
            sorting = internalSorting
        }
        .onDisappear {
            isPresented = false
        }
        .onChange(of: sorting) { sorting in
            if isPresented {
                internalSorting = sorting
            }
        }
    }

    private func sort(sorting: WatchlistViewSorting) -> (WatchlistViewItem, WatchlistViewItem) -> Bool {
        return { lhs, rhs in
            switch sorting {
            case .lastAdded:
                return lhs.addedDate > rhs.addedDate
            case .rating:
                return lhs.rating > rhs.rating
            case .name:
                return lhs.name < rhs.name
            case .release:
                return lhs.releaseDate > rhs.releaseDate
            }
        }
    }
}

#if DEBUG
import MoviebookCommon
import MoviebookTestSupport

struct WishlistListView_Previews: PreviewProvider {
    static let requestLoader = MockRequestLoader.shared
    static let watchlist = MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true))
    static var previews: some View {
        ScrollView {
            WishlistListViewPreviewView()
        }
        .environment(\.requestLoader, requestLoader)
        .environmentObject(watchlist)
    }
}

@MainActor private final class ViewModel: ObservableObject {

    @Published var items: [WatchlistViewItem] = []

    func start(watchlist: Watchlist, requestLoader: RequestLoader) async {
        let content = WatchlistViewSectionContent(section: .toWatch)
        try? await content.updateItems(watchlist.items, requestLoader: requestLoader)
        items = content.items
    }
}

private struct WishlistListViewPreviewView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject var viewModel = ViewModel()

    var body: some View {
        WishlistListView(
            sorting: .constant(.lastAdded),
            items: viewModel.items,
            onItemSelected: { _ in }
        )
        .task {
            await viewModel.start(
                watchlist: watchlist,
                requestLoader: requestLoader
            )
        }
    }
}
#endif
