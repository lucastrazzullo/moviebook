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

    @StateObject private var sectionViewModel = WatchlistSectionViewModel()
    @StateObject private var undoViewModel: WatchlistUndoViewModel = WatchlistUndoViewModel()

    @State private var shouldShowTopBar: Bool = false
    @State private var shouldShowBottomBar: Bool = false

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        ZStack {
            ContentView(
                viewModel: sectionViewModel,
                presentedItem: $presentedItem,
                shouldShowTopBar: $shouldShowTopBar,
                shouldShowBottomBar: $shouldShowBottomBar
            )
        }
        .safeAreaInset(edge: .top) {
            TopbarView(
                undoViewModel: undoViewModel,
                sorting: $sectionViewModel.sorting
            )
            .padding()
            .background(.thinMaterial.opacity(shouldShowTopBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowTopBar)
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView(
                currentSection: $sectionViewModel.section,
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
            sectionViewModel.start(watchlist: watchlist, requestManager: requestManager)
            undoViewModel.start(watchlist: watchlist, requestManager: requestManager)
        }
        .animation(.default, value: undoViewModel.removedItem)
        .animation(.default, value: sectionViewModel.items)
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

    @ObservedObject var viewModel: WatchlistSectionViewModel
    @Binding var presentedItem: NavigationItem?

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoaderView()
            } else if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
                    .frame(maxHeight: .infinity)
                    .padding()
            } else if viewModel.items.isEmpty {
                WatchlistEmptyListView(
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    section: viewModel.section
                )
            } else {
                WatchlistListView(
                    viewModel: viewModel,
                    presentedItem: $presentedItem,
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar
                )
            }
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

    @ObservedObject var viewModel: WatchlistSectionViewModel
    @Binding var presentedItem: NavigationItem?

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    var body: some View {
        GeometryReader { geometry in
            ObservableScrollView(scrollContent: $scrollContent, showsIndicators: false) { _ in
                LazyVGrid(columns: [GridItem(spacing: 4), GridItem()], spacing: 4) {
                    ForEach(viewModel.items) { item in
                        switch item {
                        case .movie(let movie, let watchlistItem):
                            WatchlistMovieItemView(
                                presentedItem: $presentedItem,
                                movie: movie,
                                watchlistIdentifier: watchlistItem.id
                            )
                        }
                    }
                }
                .padding(.horizontal, 4)
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

private struct WatchlistMovieItemView: View {

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
                    watchlistItemReleaseDate: movie.details.release,
                    presentedItem: $presentedItem
                )
            }
            .padding(10)
        }
        .id(watchlistIdentifier)
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
