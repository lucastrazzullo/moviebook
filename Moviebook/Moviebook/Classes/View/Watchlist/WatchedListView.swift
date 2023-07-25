//
//  WatchedListView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import SwiftUI
import MoviebookCommon

struct WatchedListView: View {

    let items: [WatchlistViewItem]
    let sorting: WatchlistViewSorting
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(alignment: .center) {
            StatsView(
                items: items,
                onItemSelected: onItemSelected
            )

            ListView(
                items: items,
                sorting: sorting,
                onItemSelected: onItemSelected
            )
        }
    }
}

private struct StatsView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if totalNumberOfWatchedHours > 0 || popularGenres.count > 0 {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                    Text("Stats")
                        .font(.title2)
                }

                if totalNumberOfWatchedHours > 0 {
                    VStack(spacing: 4) {
                        Text("Total time watched")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(Duration.seconds(totalNumberOfWatchedHours).formatted(.units(allowed: [.weeks, .days, .hours, .minutes, .seconds, .milliseconds], width: .wide)))
                            .font(.subheadline.bold())
                    }
                }

                if popularGenres.count > 0 {
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

                Divider()
            }
            .padding(.bottom)
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

private struct ListView: View {

    struct SortingSection: Hashable {
        let title: String
        let items: [WatchlistViewItem]
    }

    let sections: [SortingSection]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(spacing: 4), GridItem(spacing: 4), GridItem()], spacing: 4) {
            ForEach(sections, id: \.self) { section in
                Section(header: sectionHeader(section: section)) {
                    ForEach(section.items) { item in
                        switch item {
                        case .movie(let movie, _):
                            MovieShelfPreviewView(
                                movieDetails: movie.details,
                                onItemSelected: onItemSelected
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    init(items: [WatchlistViewItem], sorting: WatchlistViewSorting, onItemSelected: @escaping (NavigationItem) -> Void) {
        self.sections = Self.makeSections(items: items, sorting: sorting)
        self.onItemSelected = onItemSelected
    }

    // MARK: Private view builders

    @ViewBuilder private func sectionHeader(section: SortingSection) -> some View {
        Text(section.title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

    // MARK: Private factory methods

    private static func makeSections(items: [WatchlistViewItem], sorting: WatchlistViewSorting) -> [SortingSection] {
        switch sorting {
        case .lastAdded:
            return makeLastAddedSections(items: items)
        case .rating:
            return makeRatingSections(items: items)
        case .name:
            return makeNameSections(items: items)
        case .release:
            return makeReleaseSections(items: items)
        }
    }

    private static func makeLastAddedSections(items: [WatchlistViewItem]) -> [SortingSection] {
        var lastWeekItems: [WatchlistViewItem] = []
        var lastMonthItems: [WatchlistViewItem] = []
        var lastYearItems: [WatchlistViewItem] = []
        var allOtherItems: [WatchlistViewItem] = []

        for item in items {
            if Calendar.current.isDate(item.addedDate, equalTo: .now, toGranularity: .weekOfMonth) {
                lastWeekItems.append(item)
            } else if Calendar.current.isDate(item.addedDate, equalTo: .now, toGranularity: .month) {
                lastMonthItems.append(item)
            } else if Calendar.current.isDate(item.addedDate, equalTo: .now, toGranularity: .year) {
                lastYearItems.append(item)
            } else {
                allOtherItems.append(item)
            }
        }

        var sections: [SortingSection] = []

        if !lastWeekItems.isEmpty {
            sections.append(SortingSection(title: "Added last week", items: lastWeekItems))
        }
        if !lastMonthItems.isEmpty {
            sections.append(SortingSection(title: "Added last month", items: lastMonthItems))
        }
        if !lastYearItems.isEmpty {
            sections.append(SortingSection(title: "Added last year", items: lastYearItems))
        }
        if !allOtherItems.isEmpty {
            sections.append(SortingSection(title: "Added earlier", items: allOtherItems))
        }

        return sections
    }

    private static func makeRatingSections(items: [WatchlistViewItem]) -> [SortingSection] {
        var highRatingItems: [WatchlistViewItem] = []
        var averageRatingItems: [WatchlistViewItem] = []
        var lowRatingItems: [WatchlistViewItem] = []
        var unratedItems: [WatchlistViewItem] = []

        for item in items {
            if item.rating > 7 {
                highRatingItems.append(item)
            } else if item.rating > 5 {
                averageRatingItems.append(item)
            } else if item.rating > 0 {
                lowRatingItems.append(item)
            } else {
                unratedItems.append(item)
            }
        }

        var sections: [SortingSection] = []

        if !highRatingItems.isEmpty {
            sections.append(SortingSection(title: "Highly rated", items: highRatingItems))
        }
        if !averageRatingItems.isEmpty {
            sections.append(SortingSection(title: "Average", items: averageRatingItems))
        }
        if !lowRatingItems.isEmpty {
            sections.append(SortingSection(title: "Low rated", items: lowRatingItems))
        }
        if !unratedItems.isEmpty {
            sections.append(SortingSection(title: "Not rated", items: unratedItems))
        }

        return sections
    }

    private static func makeNameSections(items: [WatchlistViewItem]) -> [SortingSection] {
        return [
            SortingSection(title: "Alphabetical order", items: items)
        ]
    }

    private static func makeReleaseSections(items: [WatchlistViewItem]) -> [SortingSection] {
        var yearsMapping: [Int: [WatchlistViewItem]] = [:]

        for item in items {
            guard let year = Calendar.current.dateComponents([.year], from: item.releaseDate).year else {
                continue
            }

            if yearsMapping[year] == nil {
                yearsMapping[year] = []
            }

            yearsMapping[year]?.append(item)
        }

        return yearsMapping.keys.sorted(by: >).map { year in
            SortingSection(title: "Released in \(year)", items: yearsMapping[year]!)
        }
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
            sorting: .lastAdded,
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
