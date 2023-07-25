//
//  WatchedListView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import SwiftUI

struct WatchedListView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(alignment: .center) {
            StatsView(
                items: items,
                onItemSelected: onItemSelected
            )

            Divider().padding(.vertical)

            LazyVStack {
                ForEach(items) { item in
                    switch item {
                    case .movie(let movie, _):
                        MoviePreviewView(
                            details: movie.details,
                            onItemSelected: onItemSelected
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct StatsView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.largeTitle)
                Text("Stats")
                    .font(.title2)
            }

            VStack(spacing: 4) {
                Text("Total time watched")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(Duration.seconds(totalNumberOfWatchedHours).formatted(.units(allowed: [.weeks, .days, .hours, .minutes, .seconds, .milliseconds], width: .wide)))
                    .font(.subheadline.bold())
            }

            VStack(spacing: 4) {
                Text("Popular genres")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button { onItemSelected(.explore(selectedGenres: Set(popularGenres))) } label: {
                    HStack {
                        Text(popularGenres.map(\.name).joined(separator: ", "))
                            .font(.caption)
                        Image(systemName: "magnifyingglass")
                    }
                }
                .buttonStyle(OvalButtonStyle(.prominentTiny))
            }
        }
    }

    private var totalNumberOfWatchedHours: TimeInterval {
        return items.reduce(0, { total, item in
            switch item {
            case .movie(let movie, _):
                return total + (movie.details.runtime ?? 0)
            }
        })
    }

    private var popularGenres: [MovieGenre] {
        return items
            .reduce([MovieGenre]()) { list, item in
                switch item {
                case .movie(let movie, _):
                    return list + movie.genres
                }
            }
            .getMostPopular(topCap: 3)
    }
}

#if DEBUG
import MoviebookCommon
import MoviebookTestSupport

struct WatchedListView_Previews: PreviewProvider {
    static let requestLoader = MockRequestLoader.shared
    static let watchlist = MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: true, withRating: true))
    static var previews: some View {
        ScrollView {
            WatchedListViewPreviewView()
        }
        .environment(\.requestLoader, requestLoader)
        .environmentObject(watchlist)
    }
}

@MainActor private final class ViewModel: ObservableObject {

    @Published var items: [WatchlistViewItem] = []

    func start(watchlist: Watchlist, requestLoader: RequestLoader) async {
        let content = WatchlistViewSectionContent(section: .watched)
        try? await content.updateItems(watchlist.items, requestLoader: requestLoader)
        items = content.items
    }
}

private struct WatchedListViewPreviewView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject var viewModel = ViewModel()

    var body: some View {
        WatchedListView(
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
