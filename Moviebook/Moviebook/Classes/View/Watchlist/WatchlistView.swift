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

    @StateObject private var sectionViewModel = WatchlistViewModel()
    @StateObject private var undoViewModel: WatchlistUndoViewModel = WatchlistUndoViewModel()

    @State private var shouldShowTopBar: Bool = false
    @State private var shouldShowBottomBar: Bool = false

    @Binding var presentedItem: NavigationItem?

    var body: some View {
        ZStack {
            ContentView(
                viewModel: sectionViewModel,
                shouldShowTopBar: $shouldShowTopBar,
                shouldShowBottomBar: $shouldShowBottomBar,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
        }
        .safeAreaInset(edge: .top) {
            TopbarView(
                undoViewModel: undoViewModel,
                sorting: $sectionViewModel.sorting
            )
            .padding()
            .background(.thickMaterial.opacity(shouldShowTopBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowTopBar)
            .animation(.default, value: undoViewModel.removedItem)
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView(
                currentSection: $sectionViewModel.section,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
            .padding()
            .background(.thickMaterial.opacity(shouldShowBottomBar ? 1 : 0))
            .animation(.easeOut(duration: 0.12), value: shouldShowBottomBar)
        }
        .task {
            await sectionViewModel.start(watchlist: watchlist, requestManager: requestManager)
        }
        .animation(.default, value: sectionViewModel.items)
    }
}

private struct TopbarView: View {

    @ObservedObject var undoViewModel: WatchlistUndoViewModel
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

    @Binding var currentSection: WatchlistViewModel.Section

    let onItemSelected: (NavigationItem) -> Void

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

            Button(action: { onItemSelected(.explore) }) {
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

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        Group {
            if viewModel.isLoading, viewModel.items.isEmpty {
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
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    onItemSelected: onItemSelected
                )
            }
        }
    }
}

private struct WatchlistEmptyListView: View {

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewModel.Section

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

    @ObservedObject var viewModel: WatchlistViewModel

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        GeometryReader { geometry in
            ObservableScrollView(scrollContent: $scrollContent, showsIndicators: false) { _ in
                LazyVGrid(columns: [GridItem(spacing: 4), GridItem()], spacing: 4) {
                    ForEach(viewModel.items) { item in
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

#if DEBUG
import MoviebookTestSupport

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist())
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: true)))
        }

        NavigationView {
            WatchlistView(presentedItem: .constant(nil))
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
        }
    }
}
#endif
