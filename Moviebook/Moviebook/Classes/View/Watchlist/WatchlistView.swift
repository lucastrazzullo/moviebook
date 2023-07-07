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

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @AppStorage("watchlistSection") private var currentSection: WatchlistSectionViewModel.Section = .toWatch
    @AppStorage("watchlistSorting") private var currentSorting: WatchlistSectionViewModel.Sorting = .lastAdded

    @StateObject private var undoViewModel: WatchlistUndoViewModel = WatchlistUndoViewModel()

    @State private var shouldShowTopBar: Bool = false
    @State private var shouldShowBottomBar: Bool = false

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        Group {
            ForEach(WatchlistSectionViewModel.Section.allCases) { section in
                if section == currentSection {
                    ContentView(
                        presentedItem: $presentedItem,
                        shouldShowTopBar: $shouldShowTopBar,
                        shouldShowBottomBar: $shouldShowBottomBar,
                        section: section,
                        sorting: currentSorting
                    )
                }
            }
        }
        .safeAreaInset(edge: .top) {
            TopbarView(
                undoViewModel: undoViewModel,
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
        .onAppear {
            undoViewModel.start(watchlist: watchlist, requestManager: requestManager)
        }
    }
}

private struct TopbarView: View {

    @EnvironmentObject var watchlist: Watchlist

    @ObservedObject var undoViewModel: WatchlistUndoViewModel
    @Binding var sorting: WatchlistSectionViewModel.Sorting

    var body: some View {
        ZStack {
            Text("Moviebook")
                .font(.title3.bold())

            Menu {
                Picker("Sorting", selection: $sorting) {
                    ForEach(WatchlistSectionViewModel.Sorting.allCases, id: \.self) { sorting in
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
                if let removedItem = undoViewModel.removedItem {
                    HStack {
                        RemoteImage(
                            url: removedItem.imageUrl,
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(4)
                            },
                            placeholder: { Color.clear }
                        )

                        VStack(alignment: .leading) {
                            Text("Removed")
                            Button {
                                undoViewModel.undo(watchlist: watchlist, removedItem: removedItem)
                            } label: {
                                Text("undo")
                            }
                        }
                        .font(.caption)
                    }
                    .id(removedItem.id)
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
            .frame(height: 52)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.default, value: undoViewModel.removedItem)
        }
    }
}

private struct ToolbarView: View {

    @Binding var currentSection: WatchlistSectionViewModel.Section
    @Binding var presentedItem: NavigationItem?

    var body: some View {
        HStack {
            Picker("Section", selection: $currentSection) {
                ForEach(WatchlistSectionViewModel.Section.allCases, id: \.self) { section in
                    Text(section.name)
                }
            }
            .segmentedStyled()
            .fixedSize()

            Spacer()

            Button(action: { presentedItem = .explore }) {
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

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var viewModel: WatchlistSectionViewModel = WatchlistSectionViewModel()
    @Binding var presentedItem: NavigationItem?

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistSectionViewModel.Section
    let sorting: WatchlistSectionViewModel.Sorting

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
                    section: section
                )
            } else {
                WatchlistListView(
                    presentedItem: $presentedItem,
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    section: section,
                    items: viewModel.items.sorted(by: sort(lhs:rhs:))
                )
            }
        }
        .onAppear {
            viewModel.start(section: section, watchlist: watchlist, requestManager: requestManager)
        }
    }

    private func sort(lhs: WatchlistSectionViewModel.Item, rhs: WatchlistSectionViewModel.Item) -> Bool {
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

    private func rating(for item: WatchlistSectionViewModel.Item) -> Float {
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

    private func name(for item: WatchlistSectionViewModel.Item) -> String {
        switch item {
        case .movie(let movie, _, _):
            return movie.details.title
        }
    }

    private func releaseDate(for item: WatchlistSectionViewModel.Item) -> Date {
        switch item {
        case .movie(let movie, _, _):
            return movie.details.release
        }
    }

    private func addedDate(for item: WatchlistSectionViewModel.Item) -> Date {
        switch item {
        case .movie(_, _, let watchlistItem):
            return watchlistItem.date
        }
    }
}

private struct WatchlistEmptyListView: View {

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistSectionViewModel.Section

    var body: some View {
        EmptyWatchlistView(section: section)
            .background(.thinMaterial)
            .onAppear {
                shouldShowTopBar = false
                shouldShowBottomBar = false
            }
    }
}

private struct WatchlistListView: View {

    @State private var scrollContent: ObservableScrollContent = .zero

    @Binding var presentedItem: NavigationItem?

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistSectionViewModel.Section
    let items: [WatchlistSectionViewModel.Item]

    var body: some View {
        GeometryReader { geometry in
            ObservableScrollView(scrollContent: $scrollContent, showsIndicators: false) { _ in
                VStack(spacing: 0) {
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
                }

                Spacer()

                IconWatchlistButton(
                    watchlistItemIdentifier: watchlistIdentifier,
                    watchlistItemReleaseDate: movie.details.release
                )
            }
            .padding(10)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WatchlistView()
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: .init(owner: "Valerio", comment: nil)))),
                    WatchlistItem(id: .movie(id: 616037), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: nil), date: .now)))
                ]))
        }

        NavigationView {
            WatchlistView()
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: .init(owner: "Valerio", comment: nil))))
                ]))
        }

        NavigationView {
            WatchlistView()
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(Watchlist(items: []))
        }
    }
}
#endif
