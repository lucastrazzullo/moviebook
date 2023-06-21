//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import MoviebookCommon

struct WatchlistView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @AppStorage("watchlistSection") private var currentSection: WatchlistViewModel.Section = .toWatch
    @AppStorage("watchlistSorting") private var currentSorting: WatchlistViewModel.Sorting = .lastAdded

    @State private var shouldShowTopBar: Bool = false
    @State private var shouldShowBottomBar: Bool = false

    @State private var topBarHeight: CGFloat = 0
    @State private var bottomBarHeight: CGFloat = 0

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        TabView(selection: $currentSection) {
            Group {
                ForEach(WatchlistViewModel.Section.allCases) { section in
                    ContentView(
                        presentedItem: $presentedItem,
                        shouldShowTopBar: $shouldShowTopBar,
                        shouldShowBottomBar: $shouldShowBottomBar,
                        section: section,
                        sorting: currentSorting,
                        topSpacing: topBarHeight,
                        bottomSpacing: bottomBarHeight
                    )
                    .tag(section)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .background(GeometryReader { geometry in
            Color.clear
                .onAppear {
                    setBarsHeight(safeAreaInsets: geometry.safeAreaInsets)
                }
                .onChange(of: geometry.safeAreaInsets) { safeAreaInsets in
                    setBarsHeight(safeAreaInsets: safeAreaInsets)
                }
        })
        .watchlistPrompt(duration: 5)
        .safeAreaInset(edge: .top) {
            TopbarView(
                sorting: $currentSorting
            )
            .padding()
            .background(.thinMaterial.opacity(shouldShowTopBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowTopBar)
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView(
                currentSection: $currentSection,
                presentedItem: $presentedItem
            )
            .padding()
            .background(.thinMaterial.opacity(shouldShowBottomBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowBottomBar)
        }
        .sheet(item: $presentedItem) { item in
            Navigation(path: $presentedItemNavigationPath, presentingItem: item)
        }
    }

    private func setBarsHeight(safeAreaInsets: EdgeInsets) {
        topBarHeight = safeAreaInsets.top / 2 + 20
        bottomBarHeight = safeAreaInsets.bottom
    }
}

private struct TopbarView: View {

    @Binding var sorting: WatchlistViewModel.Sorting

    var body: some View {
        ZStack {
            Text("Moviebook")
                .font(.title3.bold())

            Menu {
                Picker("Sorting", selection: $sorting) {
                    ForEach(WatchlistViewModel.Sorting.allCases, id: \.self) { sorting in
                        HStack {
                            Text(sorting.label)
                            Spacer()
                            Image(systemName: sorting.image)
                        }
                        .tag(sorting)
                    }
                }
            } label: {
                WatermarkView {
                    Image(systemName: "arrow.up.and.down.text.horizontal")
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

private struct ToolbarView: View {

    @Binding var currentSection: WatchlistViewModel.Section
    @Binding var presentedItem: NavigationItem?

    var body: some View {
        HStack {
            Picker("Section", selection: $currentSection) {
                ForEach(WatchlistViewModel.Section.allCases, id: \.self) { section in
                    Text(section.name)
                }
            }
            .segmentedStyled()
            .fixedSize()

            Spacer()

            Button(action: { presentedItem = .explore }) {
                WatermarkView {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}

private struct ContentView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var viewModel: WatchlistViewModel = WatchlistViewModel()
    @Binding var presentedItem: NavigationItem?

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewModel.Section
    let sorting: WatchlistViewModel.Sorting

    let topSpacing: CGFloat
    let bottomSpacing: CGFloat

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoaderView()
            } else if let error = viewModel.error {
                RetriableErrorView(retry: error.retry).padding()
            } else if viewModel.items.isEmpty {
                WatchlistEmptyListView(
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    section: section,
                    topSpacing: topSpacing,
                    bottomSpacing: bottomSpacing
                )
            } else {
                WatchlistListView(
                    presentedItem: $presentedItem,
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    section: section,
                    items: viewModel.items.sorted(by: sort(lhs:rhs:)),
                    topSpacing: topSpacing,
                    bottomSpacing: bottomSpacing
                )
            }
        }
        .onAppear {
            viewModel.start(section: section, watchlist: watchlist, requestManager: requestManager)
        }
    }

    private func sort(lhs: WatchlistViewModel.Item, rhs: WatchlistViewModel.Item) -> Bool {
        switch sorting {
        case .lastAdded:
            return addedDate(for: lhs) > addedDate(for: rhs)
        case .rating:
            return rating(for: lhs) > rating(for: rhs)
        case .name:
            return name(for: lhs) < name(for: rhs)
        case .release:
            return releaseDate(for: lhs) < releaseDate(for: rhs)
        }
    }

    private func rating(for item: WatchlistViewModel.Item) -> Float {
        switch item {
        case .movie(let movie, _, let watchlistItem):
            switch watchlistItem.state {
            case .toWatch:
                return movie.details.rating.value
            case .watched(let info):
                return Float(info.rating ?? 0)
            }
        }
    }

    private func name(for item: WatchlistViewModel.Item) -> String {
        switch item {
        case .movie(let movie, _, _):
            return movie.details.title
        }
    }

    private func releaseDate(for item: WatchlistViewModel.Item) -> Date {
        switch item {
        case .movie(let movie, _, _):
            return movie.details.release
        }
    }

    private func addedDate(for item: WatchlistViewModel.Item) -> Date {
        switch item {
        case .movie(_, _, let watchlistItem):
            return watchlistItem.date
        }
    }
}

private struct WatchlistEmptyListView: View {

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewModel.Section
    let topSpacing: CGFloat
    let bottomSpacing: CGFloat

    var body: some View {
        EmptyWatchlistView(section: section)
            .padding(.top, topSpacing - 20)
            .padding(.bottom, bottomSpacing / 2)
            .onAppear {
                shouldShowTopBar = true
                shouldShowBottomBar = true
            }
    }
}

private struct WatchlistListView: View {

    @State private var scrollContent: ObservableScrollContent = .zero

    @Binding var presentedItem: NavigationItem?

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewModel.Section
    let items: [WatchlistViewModel.Item]
    let topSpacing: CGFloat
    let bottomSpacing: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ObservableScrollView(scrollContent: $scrollContent, showsIndicators: false) { _ in
                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacing)

                    LazyVGrid(columns: [GridItem(spacing: 4), GridItem()], spacing: 4) {
                        ForEach(items) { item in
                            switch item {
                            case .movie(let movie, _, let watchlistItem):
                                WatchlistItemView(
                                    presentedItem: $presentedItem,
                                    movie: movie,
                                    watchlistIdentifier: watchlistItem.id
                                )
                                .id(item.id)
                                .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    Spacer().frame(height: bottomSpacing)
                }
                .animation(.default, value: items)
                .onChange(of: scrollContent) { info in
                    updateShouldShowBars(geometry: geometry)
                }
                .onChange(of: geometry.safeAreaInsets) { _ in
                    updateShouldShowBars(geometry: geometry)
                }
            }
        }
    }

    private func updateShouldShowBars(geometry: GeometryProxy) {
        shouldShowTopBar = scrollContent.offset > 0
        shouldShowBottomBar = -(scrollContent.offset - scrollContent.height) > geometry.size.height + 20
    }
}

private struct WatchlistItemView: View {

    @EnvironmentObject var watchlist: Watchlist

    @Binding var presentedItem: NavigationItem?

    let movie: Movie
    let watchlistIdentifier: WatchlistItemIdentifier

    var body: some View {
        Group {
            RemoteImage(url: movie.details.media.posterPreviewUrl) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                presentedItem = .movie(movie)
            }
        }
        .overlay(alignment: .bottom) {
            HStack(alignment: .center) {
                if movie.details.release > Date.now {
                    HStack(spacing: 4) {
                        Text("Release")
                        Text(movie.details.release, format: .dateTime.year())
                    }
                    .font(.caption2).bold()
                    .padding(6)
                    .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                    .foregroundColor(.black)
                    .padding(.leading, 12)
                }

                Spacer()

                Menu {
                    Button(action: { presentedItem = .movie(movie) }) { Label("Open", systemImage: "chevron.up") }
                    Menu {
                        WatchlistOptions(
                            presentedItem: $presentedItem,
                            watchlistItemIdentifier: watchlistIdentifier
                        )
                    } label: {
                        WatchlistLabel(itemState: watchlist.itemState(id: watchlistIdentifier))
                    }
                } label: {
                    WatermarkView {
                        WatchlistIcon(itemState: watchlist.itemState(id: watchlistIdentifier))
                    }
                }
                .padding(12)
            }
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: nil), date: .now)))
            ]))

        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))

        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
    }
}
#endif
