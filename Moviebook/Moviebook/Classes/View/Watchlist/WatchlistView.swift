//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import Combine
import MoviebookCommon

struct WatchlistView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var contentViewModel: WatchlistViewModel = WatchlistViewModel()
    @StateObject private var undoViewModel: WatchlistUndoViewModel = WatchlistUndoViewModel()

    @State private var section: WatchlistViewSection = .toWatch
    @State private var shouldShowTopBar: Bool = false
    @State private var shouldShowBottomBar: Bool = false

    @Binding var presentedItem: NavigationItem?

    var body: some View {
        ZStack {
            ContentView(
                viewModel: contentViewModel,
                shouldShowTopBar: $shouldShowTopBar,
                shouldShowBottomBar: $shouldShowBottomBar,
                section: section,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
        }
        .safeAreaInset(edge: .top) {
            TopbarView(
                undoViewModel: undoViewModel,
                sorting: Binding(
                    get: { contentViewModel.sorting(in: section) },
                    set: { contentViewModel.update(sorting: $0, in: section) }
                )
            )
            .padding(.horizontal)
            .background(.thickMaterial.opacity(shouldShowTopBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowTopBar)
            .animation(.default, value: undoViewModel.removedItem)
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView(
                currentSection: $section,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
            .padding()
            .background(.thickMaterial.opacity(shouldShowBottomBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowBottomBar)
        }
        .task {
            await contentViewModel.start(watchlist: watchlist, requestLoader: requestLoader)
        }
        .animation(.default, value: contentViewModel.items(in: section))
        .animation(.default, value: contentViewModel.sorting(in: section))
    }
}

private struct TopbarView: View {

    @ObservedObject var undoViewModel: WatchlistUndoViewModel
    @Binding var sorting: WatchlistViewSorting

    var body: some View {
        ZStack {
            Text("Moviebook")
                .font(.title3.bold())

            Menu {
                Picker("Sorting", selection: $sorting) {
                    ForEach(WatchlistViewSorting.allCases, id: \.self) { sorting in
                        HStack {
                            Text(sorting.label)
                            Spacer()
                            Image(systemName: sorting.image)
                        }
                        .tag(sorting)
                    }
                }
            } label: {
                Image(systemName: "arrow.up.and.down.text.horizontal")
                    .frame(width: 18, height: 18, alignment: .center)
                    .ovalStyle(.normal)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)

            VStack {
                WatchlistUndoView(undoViewModel: undoViewModel)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ToolbarView: View {

    @Binding var currentSection: WatchlistViewSection

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        HStack {
            Picker("Section", selection: $currentSection) {
                ForEach(WatchlistViewSection.allCases, id: \.self) { section in
                    Text(section.name)
                }
            }
            .segmentedStyled()
            .fixedSize()

            Spacer()

            Button(action: { onItemSelected(.explore(selectedGenres: [])) }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Browse")
                }
            }
            .buttonStyle(OvalButtonStyle(.prominentSmall))
            .fixedSize()
        }
    }
}

private struct ContentView: View {

    @State private var scrollContent: [WatchlistViewSection: ObservableScrollContent] = [:]

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewSection
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading, viewModel.items(in: section).isEmpty {
                LoaderView()
            } else if let error = viewModel.error {
                RetriableErrorView(error: error)
                    .frame(maxHeight: .infinity)
                    .padding()
            } else {
                GeometryReader { geometry in
                    SectionListView(
                        scrollContent: Binding(
                            get: { scrollContent[section] ?? .zero },
                            set: { scrollContent in self.scrollContent[section] = scrollContent }
                        ),
                        section: section,
                        groups: viewModel.items(in: section),
                        onItemSelected: onItemSelected
                    )
                    .onChange(of: scrollContent) { info in
                        updateShouldShowBars(geometry: geometry)
                    }
                    .onChange(of: geometry.safeAreaInsets) { _ in
                        updateShouldShowBars(geometry: geometry)
                    }
                    .onChange(of: section) { _ in
                        updateShouldShowBars(geometry: geometry)
                    }
                }
            }
        }
    }

    private func updateShouldShowBars(geometry: GeometryProxy) {
        if viewModel.items(in: section).isEmpty {
            shouldShowTopBar = true
            shouldShowBottomBar = true
        } else if let scrollContent = scrollContent[section] {
            shouldShowTopBar = scrollContent.offset > 0 + 10
            shouldShowBottomBar = -(scrollContent.offset - scrollContent.height) > geometry.size.height + 20
        }
    }
}

private struct SectionListView: View {

    @Binding var scrollContent: ObservableScrollContent

    let section: WatchlistViewSection
    let groups: [WatchlistViewItemGroup]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ZStack {
            ForEach(WatchlistViewSection.allCases) { section in
                Group {
                    if groups.isEmpty {
                        EmptyWatchlistView(section: section)
                    } else {
                        ObservableScrollView(scrollContent: $scrollContent, showsIndicators: false) { _ in
                            ListView(
                                section: section,
                                groups: groups,
                                onItemSelected: onItemSelected
                            )
                        }
                    }
                }
                .id(section.id)
                .opacity(self.section == section ? 1 : 0)
            }
        }
    }
}

private struct ListView: View {

    let section: WatchlistViewSection
    let groups: [WatchlistViewItemGroup]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack {
            StatsView(
                section: section,
                items: groups.flatMap(\.items),
                onItemSelected: onItemSelected
            )

            ForEach(Array(zip(groups.indices, groups)), id: \.0) { index, group in
                VStack {
                    WatchlistGroupHeader(group: group)
                    ForEach(group.items, id: \.self) { item in
                        WatchlistItemView(
                            item: item,
                            onItemSelected: onItemSelected
                        )
                    }
                    WatchlistGroupFooter(
                        group: group,
                        section: section,
                        onItemSelected: onItemSelected
                    )
                }
                .padding(.horizontal, 4)
                .background((index % 2) != 0 ? WatchlistGroupBackground(group: group) : nil)
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct WatchlistGroupBackground: View {

    let group: WatchlistViewItemGroup

    var body: some View {
        GeometryReader { geometry in
            if let backgroungImage = group.imageUrl {
                RemoteImage(
                    url: backgroungImage,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                    },
                    placeholder: { Color.clear }
                )
                .overlay(Rectangle()
                    .fill(.background.opacity(0.65))
                    .background(.thinMaterial)
                )
                .cornerRadius(8)
            }
        }
    }
}

private struct WatchlistGroupHeader: View {

    let group: WatchlistViewItemGroup

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let icon = group.icon {
                Image(systemName: icon)
            }

            if let title = group.title {
                Text(title)
            }
        }
        .font(.title3.bold())
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

private struct WatchlistGroupFooter: View {

    enum Section: Int {
        case toWatch
        case watched
        case notInWatchlist

        var title: String {
            switch self {
            case .toWatch:
                return "To watch"
            case .watched:
                return "Watched"
            case .notInWatchlist:
                return "Not in your watchlist"
            }
        }

        var icon: String {
            switch self {
            case .toWatch:
                return WatchlistViewState.toWatch.icon
            case .watched:
                return WatchlistViewState.watched.icon
            case .notInWatchlist:
                return WatchlistViewState.none.icon
            }
        }
    }

    @EnvironmentObject var watchlist: Watchlist

    @State private var showEntireCollection: Bool = false

    let group: WatchlistViewItemGroup
    let section: WatchlistViewSection
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if !moreItemsToShow.isEmpty {
            Group {
                if showEntireCollection {
                    VStack(alignment: .leading) {
                        let sections = Array(moreItemsToShow.keys)
                            .sorted { $0.rawValue < $1.rawValue }

                        ForEach(sections, id: \.self) { section in
                            VStack(alignment: .leading) {
                                if let items = moreItemsToShow[section] {
                                    HStack(alignment: .firstTextBaseline) {
                                        Image(systemName: section.icon)
                                        Text(section.title.uppercased())
                                    }
                                    .font(.subheadline)
                                    .padding(.top)

                                    Divider()

                                    ForEach(items, id: \.self) { item in
                                        switch item {
                                        case .movie(let item, _):
                                            MoviePreviewView(
                                                details: item.details,
                                                style: .poster,
                                                onItemSelected: onItemSelected
                                            )
                                        }
                                    }
                                }
                            }
                            .id(section)
                        }
                    }
                } else {
                    VStack(alignment: .leading) {
                        Divider()

                        HStack(alignment: .firstTextBaseline) {
                            Image(systemName: "plus.square.on.square")

                            VStack(alignment: .leading) {
                                if let title = group.title {
                                    Text("More in **\(title)**")
                                } else {
                                    Text("There's more")
                                }

                                Button { showEntireCollection = true } label: {
                                    Text("Show all")
                                    Image(systemName: "chevron.down")
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private var moreItemsToShow: [Section: [WatchlistViewItem]] {
        var result = [Section: [WatchlistViewItem]]()

        for item in group.expandableItems {
            switch watchlist.itemState(id: item.watchlistIdentifier) {
            case .toWatch where section != .toWatch:
                let section = Section.toWatch
                if result[section] == nil {
                    result[section] = []
                }
                result[section]?.append(item)
            case .watched where section != .watched:
                let section = Section.watched
                if result[section] == nil {
                    result[section] = []
                }
                result[section]?.append(item)
            case .none:
                let section = Section.notInWatchlist
                if result[section] == nil {
                    result[section] = []
                }
                result[section]?.append(item)
            default:
                continue
            }
        }

        return result
    }
}

private struct WatchlistItemView: View {

    let item: WatchlistViewItem
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            RemoteImage(url: item.imageUrl, content: { image in
                image.resizable().aspectRatio(contentMode: .fit)
            }, placeholder: {
                Rectangle().fill(.clear)
            })
            .cornerRadius(6)
            .onTapGesture(perform: handleTap)

            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.title3)
                        .lineLimit(3)

                    if item.releaseDate > .now {
                        Text("Coming on \(item.releaseDate.formatted(.dateTime.year()))")
                            .bold()
                            .padding(4)
                            .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                            .foregroundColor(.black)
                            .font(.caption)
                    } else {
                        Text(item.releaseDate, format: .dateTime.year())
                            .font(.caption)
                    }

                    RatingView(rating: item.rating)
                        .padding(.top, 4)
                }
                .onTapGesture(perform: handleTap)

                Spacer()

                IconWatchlistButton(
                    watchlistItemIdentifier: item.watchlistIdentifier,
                    watchlistItemReleaseDate: item.releaseDate,
                    onItemSelected: onItemSelected
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .id(item.watchlistIdentifier)
    }

    private func handleTap() {
        switch item {
        case .movie(let movieItem, _):
            onItemSelected(.movieWithIdentifier(movieItem.details.id))
        }
    }
}

private struct StatsView: View {

    let section: WatchlistViewSection
    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if totalNumberOfWatchedHours > 0 || popularGenres.count > 0 {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                    Text("\(section.name) stats")
                        .font(.title2)
                }

                if totalNumberOfWatchedHours > 0 {
                    VStack(spacing: 4) {
                        Text("Total time")
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
            case .movie(let item, _):
                return total + (item.details.runtime ?? 0)
            }
        })
    }

    private var popularGenres: [MovieGenre] {
        return items
            .reduce([MovieGenre]()) { list, item in
                switch item {
                case .movie(let item, _):
                    return list + item.genres
                }
            }
            .getMostPopular(topCap: 3)
    }
}

#if DEBUG
import MoviebookTestSupport

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestLoader, MockRequestLoader.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist())
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestLoader, MockRequestLoader.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true)))
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestLoader, MockRequestLoader.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
        }
    }
}
#endif
