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
    @EnvironmentObject var favourites: Favourites

    @StateObject private var contentViewModel: WatchlistViewModel = WatchlistViewModel()
    @StateObject private var undoViewModel: WatchlistUndoViewModel = WatchlistUndoViewModel()

    @State private var currentSection: WatchlistViewSection = .toWatch
    @State private var scrollContent: [WatchlistViewSection: ObservableScrollContent] = [:]
    @State private var scrollInsets: CGFloat = 0
    @State private var shouldShowTopBackground: Bool = false
    @State private var shouldShowBottomBackground: Bool = false

    @Binding var presentedItem: NavigationItem?

    var body: some View {
        ZStack {
            ContentView(
                viewModel: contentViewModel,
                scrollContent: $scrollContent,
                scrollInsets: $scrollInsets,
                shouldShowTopBackground: $shouldShowTopBackground,
                shouldShowBottomBackground: $shouldShowBottomBackground,
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
            .background(.background.opacity(shouldShowTopBackground ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowTopBackground)
            .animation(.default, value: undoViewModel.removedItem)
        }
        .safeAreaInset(edge: .bottom) {
            BottomView(
                currentSection: $currentSection,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
            .padding()
            .background(.background.opacity(shouldShowBottomBackground ? 1 : 0))
            .overlay(Rectangle().fill(.thinMaterial).frame(height: 1).opacity(shouldShowBottomBackground ? 1 : 0), alignment: .top)
            .animation(.easeOut(duration: 0.12), value: shouldShowBottomBackground)
        }
        .task {
            await contentViewModel.start(watchlist: watchlist, favourites: favourites, requestLoader: requestLoader)
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
            Text("Moviebook".uppercased())
                .font(.hero)
                .padding(.top, 8)

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

// MARK: - Bottom View

extension WatchlistViewSection: MenuSelectorItem {

    var label: String {
        return self.name
    }

    var badge: Int {
        return 0
    }
}

private struct BottomView: View {

    @Binding var currentSection: WatchlistViewSection

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            MenuSelector(
                selection: $currentSection,
                items: WatchlistViewSection.allCases
            )
            .tint(.accentColor)

            Spacer()

            Button(action: { onItemSelected(.explore(selectedGenres: [])) }) {
                HStack(spacing: 4) {
                    Text("Discover".uppercased())
                        .foregroundColor(.primary)
                        .font(.heroHeadline)

                    Image(systemName: "text.magnifyingglass")
                        .font(.heroHeadline)
                        .padding(.bottom, 6)
                }
            }
        }
    }
}

// MARK: - Content

private struct ContentView: View {

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var scrollContent: [WatchlistViewSection: ObservableScrollContent]
    @Binding var scrollInsets: CGFloat
    @Binding var shouldShowTopBackground: Bool
    @Binding var shouldShowBottomBackground: Bool

    let currentSection: WatchlistViewSection
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.isLoading {
                LoaderView()
            } else if let error = viewModel.error {
                RetriableErrorView(error: error)
            } else {
                SectionsView(
                    viewModel: viewModel,
                    scrollContent: $scrollContent,
                    scrollInsets: $scrollInsets,
                    shouldShowTopBackground: $shouldShowTopBackground,
                    shouldShowBottomBackground: $shouldShowBottomBackground,
                    currentSection: currentSection,
                    onItemSelected: onItemSelected
                )

                WatchlistPinnedArtistsView(
                    viewModel: viewModel,
                    scrollContent: $scrollContent[currentSection],
                    scrollInsets: $scrollInsets,
                    shouldShowBackground: shouldShowTopBackground,
                    onItemSelected: onItemSelected
                )
            }
        }
    }
}

// MARK: - Pinned Artists

private struct WatchlistPinnedArtistsView: View {

    @EnvironmentObject var watchlist: Watchlist

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var scrollContent: ObservableScrollContent?
    @Binding var scrollInsets: CGFloat

    let shouldShowBackground: Bool
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if !watchlist.items.isEmpty {
            VStack(alignment: .center, spacing: 8) {
                Text("Favourite artists".uppercased())
                    .font(.heroSubheadline)

                Capsule()
                    .foregroundColor(.secondaryAccentColor)
                    .frame(width: 28, height: 4)

                Group {
                    if !viewModel.pinnedArtists().isEmpty {
                        PinnedArtistsView(
                            list: viewModel.pinnedArtists(),
                            onItemSelected: onItemSelected
                        )
                    } else {
                        Text("Here you can pin your favourite artists")
                            .font(.caption)

                        HStack {
                            ForEach(0...4, id: \.self) { index in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .foregroundStyle(.thinMaterial)

                                    if index == 0 {
                                        Image(systemName: "plus")
                                    }
                                }
                                .onTapGesture {
                                    onItemSelected(.popularArtists)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .frame(minHeight: 24)
            }
            .padding(.bottom)
            .background(.background.opacity(shouldShowBackground ? 1 : 0))
            .overlay(Rectangle().fill(.thinMaterial).frame(height: 1).opacity(shouldShowBackground ? 1 : 0), alignment: .bottom)
            .frame(height: max(0, min(160, 160 - (scrollContent?.offset ?? 0))))
            .animation(.easeOut(duration: 0.12), value: scrollContent?.offset)
            .onAppear {
                scrollInsets = 160
            }
        }
    }
}

// MARK: - Sections

private struct SectionsView: View {

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var scrollContent: [WatchlistViewSection: ObservableScrollContent]
    @Binding var scrollInsets: CGFloat

    @Binding var shouldShowTopBackground: Bool
    @Binding var shouldShowBottomBackground: Bool

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
                        scrollInsets: $scrollInsets,
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
            shouldShowTopBackground = false
            shouldShowBottomBackground = false
        } else if let scrollContent = scrollContent[currentSection] {
            shouldShowTopBackground = scrollContent.offset > 0 + 10
            shouldShowBottomBackground = -(scrollContent.offset - scrollContent.height) > geometry.size.height + 20
        }
    }
}

private struct SectionListView: View {

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var scrollContent: ObservableScrollContent
    @Binding var scrollInsets: CGFloat

    let section: WatchlistViewSection
    let groups: [WatchlistViewItemGroup]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if groups.isEmpty {
            EmptyWatchlistView(section: section)
        } else {
            ObservableScrollView(scrollContent: $scrollContent, topInset: scrollInsets, showsIndicators: false) { _ in
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

    private let colors: [Color] = [
        .tertiaryAccentColor,
        .secondaryAccentColor,
        .accentColor
    ]

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
                WatchlistGroupView(
                    color: colors.rotateLeft(distance: index).first ?? .accentColor,
                    section: section,
                    group: group,
                    onItemSelected: onItemSelected
                )
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
                    items: specs,
                    showDividers: true
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
            return .list(list, label: section.name)
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

private struct WatchlistGroupView: View {

    let color: Color
    let section: WatchlistViewSection
    let group: WatchlistViewItemGroup
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack {
            WatchlistGroupHeader(
                group: group,
                color: color
            )

            ForEach(group.items, id: \.self) { item in
                WatchlistItemView(
                    color: color,
                    item: item,
                    onItemSelected: onItemSelected
                )
            }
            WatchlistGroupFooter(
                color: color,
                group: group,
                section: section,
                onItemSelected: onItemSelected
            )
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
    let color: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let icon = group.icon {
                Image(systemName: icon)
                    .font(.subheadline.bold())
            }

            if let title = group.title {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title.uppercased())
                        .font(.heroSubheadline)

                    Capsule(style: .continuous)
                        .fill(color)
                        .frame(width: 28, height: 4)
                }
            }
        }
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

    let color: Color
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
                                    .font(.heroSubheadline)
                                    .padding(.top)

                                    Divider()

                                    ForEach(items, id: \.self) { item in
                                        switch item {
                                        case .movie(let movieItem, _):
                                            HStack {
                                                if let position = item.position {
                                                    Text(position, format: .number)
                                                        .font(.heroHeadline)
                                                        .foregroundColor(color)
                                                }

                                                MoviePreviewView(
                                                    details: movieItem.details,
                                                    style: .poster,
                                                    onItemSelected: onItemSelected
                                                )
                                            }
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

    let color: Color
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

            HStack(alignment: .top) {
                if let position = item.position {
                    Text(position, format: .number)
                        .foregroundColor(color)
                        .font(.heroHeadline)
                        .padding(.top, 8)
                }

                VStack(alignment: .leading) {
                    Text(item.name)
                        .font(.heroHeadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(3)
                        .padding(.top, 8)

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
                .environmentObject(Favourites(items: [.init(id: .artist(id: 287), state: .pinned)]))
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestLoader, MockRequestLoader.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true)))
                .environmentObject(Favourites(items: []))
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestLoader, MockRequestLoader.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
                .environmentObject(Favourites(items: [.init(id: .artist(id: 287), state: .pinned)]))
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestLoader, MockRequestLoader.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
                .environmentObject(Favourites(items: []))
        }
    }
}
#endif
