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

    @State private var currentSection: WatchlistViewSection = .toWatch
    @State private var shouldShowTopBar: Bool = false
    @State private var shouldShowBottomBar: Bool = false

    @Binding var presentedItem: NavigationItem?

    var body: some View {
        ZStack {
            ContentView(
                viewModel: contentViewModel,
                shouldShowTopBar: $shouldShowTopBar,
                shouldShowBottomBar: $shouldShowBottomBar,
                currentSection: currentSection,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
        }
        .safeAreaInset(edge: .top) {
            TopbarView(
                undoViewModel: undoViewModel,
                sorting: Binding(
                    get: { contentViewModel.sorting(in: currentSection) },
                    set: { contentViewModel.update(sorting: $0, in: currentSection) }
                )
            )
            .padding(.horizontal)
            .background(.thickMaterial.opacity(shouldShowTopBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowTopBar)
            .animation(.default, value: undoViewModel.removedItem)
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView(
                currentSection: $currentSection,
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
        .animation(.default, value: contentViewModel.items(in: currentSection))
        .animation(.default, value: contentViewModel.sorting(in: currentSection))
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

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let currentSection: WatchlistViewSection
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoaderView()
            } else if let error = viewModel.error {
                RetriableErrorView(error: error)
            } else {
                SectionsView(
                    viewModel: viewModel,
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    currentSection: currentSection,
                    onItemSelected: onItemSelected
                )
            }
        }
    }
}

private struct SectionsView: View {

    @State private var scrollContent: [WatchlistViewSection: ObservableScrollContent] = [:]

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let currentSection: WatchlistViewSection
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(WatchlistViewSection.allCases, id: \.self) { section in
                    let groups = viewModel.items(in: section)

                    SectionListView(
                        viewModel: viewModel,
                        scrollContent: Binding(
                            get: { scrollContent[section] ?? .zero },
                            set: { scrollContent in self.scrollContent[section] = scrollContent }
                        ),
                        section: currentSection,
                        groups: groups,
                        onItemSelected: onItemSelected
                    )
                    .id(section.id)
                    .opacity(currentSection == section ? 1 : 0)
                }
            }
            .onChange(of: scrollContent) { info in
                updateShouldShowBars(geometry: geometry, currentSection: currentSection)
            }
            .onChange(of: geometry.safeAreaInsets) { _ in
                updateShouldShowBars(geometry: geometry, currentSection: currentSection)
            }
            .onChange(of: currentSection) { currentSection in
                updateShouldShowBars(geometry: geometry, currentSection: currentSection)
            }
        }
    }

    private func updateShouldShowBars(geometry: GeometryProxy, currentSection: WatchlistViewSection) {
        if viewModel.items(in: currentSection).isEmpty {
            shouldShowTopBar = true
            shouldShowBottomBar = true
        } else if let scrollContent = scrollContent[currentSection] {
            shouldShowTopBar = scrollContent.offset > 0 + 10
            shouldShowBottomBar = -(scrollContent.offset - scrollContent.height) > geometry.size.height + 20
        }
    }
}

private struct SectionListView: View {

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var scrollContent: ObservableScrollContent

    let section: WatchlistViewSection
    let groups: [WatchlistViewItemGroup]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
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
}

private struct ListView: View {

    let section: WatchlistViewSection
    let groups: [WatchlistViewItemGroup]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack {
            WatchlistListHeaderView(
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
                .padding(.bottom)
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct WatchlistListHeaderView: View {

    let section: WatchlistViewSection
    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if !specs.isEmpty {
            VStack {
                SpecsView(
                    title: section.name,
                    items: specs,
                    showDividers: false
                )

                Divider()
            }
            .padding(.bottom)
        }
    }

    private var specs: [SpecsView.Item] {
        var specs = [SpecsView.Item?]()
        specs.append(totalNumberOfItems)
        specs.append(totalNumberOfWatchedHours)
        specs.append(popularGenres)
        specs.append(unratedItems)

        return specs.compactMap({$0})
    }

    private var totalNumberOfItems: SpecsView.Item? {
        let list = items
            .reduce([String: Int]()) { mapping, item in
                switch item {
                case .movie:
                    var mapping = mapping
                    mapping["movies"] = (mapping["movies"] ?? 0) + 1
                    return mapping
                }
            }
            .map { key, value in
                return "\(value) \(key)"
            }

        if !list.isEmpty {
            return .list(list, label: "Number of items")
        } else {
            return nil
        }
    }

    private var totalNumberOfWatchedHours: SpecsView.Item? {
        let duration = items.reduce(0, { total, item in
            switch item {
            case .movie(let item, _):
                return total + (item.details.runtime ?? 0)
            }
        })

        if duration > 0 {
            return .duration(duration, label: "Total time")
        } else {
            return nil
        }
    }

    private var popularGenres: SpecsView.Item? {
        let genres = items
            .reduce([MovieGenre]()) { list, item in
                switch item {
                case .movie(let item, _):
                    return list + item.genres
                }
            }
            .getMostPopular()
            .sorted(by: { $0.name < $1.name })
            .cap(top: 3)

        if !genres.isEmpty {
            return .button(
                { onItemSelected(.explore(selectedGenres: Set(genres))) },
                buttonLabel: genres.map(\.name).joined(separator: " "),
                label: "Popular genres"
            )
        } else {
            return nil
        }
    }

    private var unratedItems: SpecsView.Item? {
        let unratedItems = items
            .filter { item in
                switch item {
                case .movie(_, let watchlistItem):
                    switch watchlistItem?.state {
                    case .watched(let info) where info.rating == nil:
                        return true
                    default:
                        return false
                    }
                }
            }

        if !unratedItems.isEmpty {
            return .button(
                { onItemSelected(.unratedItems(unratedItems)) },
                buttonLabel: "\(unratedItems.count) to rate",
                label: "Unrated items"
            )
        } else {
            return nil
        }
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
                Text(title.uppercased())
            }
        }
        .font(.subheadline.bold())
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .padding(.top, 4)
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
            let sections = Array(moreItemsToShow.keys)
                .sorted { $0.rawValue < $1.rawValue }

            Group {
                if showEntireCollection {
                    VStack(alignment: .leading) {
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

                        VStack(alignment: .leading, spacing: 6) {
                            Group {
                                if let title = group.title {
                                    Text("More in **\(title)**")
                                } else {
                                    Text("There's more")
                                }
                            }
                            .foregroundColor(.secondary)

                            ForEach(sections, id: \.self) { section in
                                if let items = moreItemsToShow[section] {
                                    Text("**^[\(items.count) item](inflect: true)** \(section.title.lowercased())")
                                }
                            }

                            Button { showEntireCollection = true } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    Text("Show all")
                                    Image(systemName: "plus.square.on.square")
                                }
                            }
                            .buttonStyle(OvalButtonStyle(.normal))
                            .padding(.top, 8)
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
            RemoteImage(url: item.backdropUrl, content: { image in
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
                            .background(Color.secondaryAccentColor, in: RoundedRectangle(cornerRadius: 6))
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
