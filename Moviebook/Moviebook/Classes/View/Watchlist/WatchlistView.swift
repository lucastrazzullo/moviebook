//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct WatchlistView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @State private var currentSection: WatchlistViewModel.Section = .toWatch
    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        TabView(selection: $currentSection) {
            Group {
                ForEach(WatchlistViewModel.Section.allCases) { section in
                    ContentView(
                        presentedItem: $presentedItem,
                        scrollOffset: $scrollOffset,
                        section: section
                    )
                    .tag(section)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .safeAreaInset(edge: .top) {
            TopBarView()
                .padding(.vertical, 6)
                .transition(.opacity)
                .background(.regularMaterial.opacity(scrollOffset > 0 ? 1 : 0))
                .animation(.easeIn(duration: 0.125), value: scrollOffset)
        }
        .safeAreaInset(edge: .bottom) {
            ToolbarView(
                currentSection: $currentSection,
                presentedItem: $presentedItem
            )
            .padding()
            .background(.thickMaterial)
        }
        .watchlistPrompt(duration: 5)
        .sheet(item: $presentedItem) { item in
            Navigation(path: $presentedItemNavigationPath, presentingItem: item)
        }
    }
}

private struct TopBarView: View {

    var body: some View {
        Group {
            Image("Moviebook")
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .foregroundColor(.primary)
        .frame(height: 32)
        .frame(maxWidth: .infinity)
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

            WatermarkView {
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        presentedItem = .explore
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
    @Binding var scrollOffset: CGFloat

    let section: WatchlistViewModel.Section

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoaderView()
            } else if viewModel.items.isEmpty {
                EmptyWatchlistView(section: section)
            } else {
                WatchlistListView(
                    presentedItem: $presentedItem,
                    scrollOffset: $scrollOffset,
                    section: section,
                    items: viewModel.items
                )
            }
        }
        .onAppear {
            viewModel.start(section: section, watchlist: watchlist, requestManager: requestManager)
        }
    }
}

private struct WatchlistListView: View {

    @Binding var presentedItem: NavigationItem?
    @Binding var scrollOffset: CGFloat

    let section: WatchlistViewModel.Section
    let items: [WatchlistViewModel.Item]

    var body: some View {
        GeometryReader { geometry in
            let topSpacing = geometry.safeAreaInsets.top
            let bottomSpacing = geometry.safeAreaInsets.bottom + 32

            ObservableScrollView(scrollOffset: $scrollOffset, showsIndicators: false) { _ in
                VStack(spacing: 0) {
                    Spacer().frame(height: topSpacing)

                    LazyVGrid(columns: [GridItem(), GridItem()]) {
                        ForEach(items) { item in
                            switch item {
                            case .movie(let movie, _, let watchlistIdentifier):
                                WatchlistItemView(
                                    presentedItem: $presentedItem,
                                    movie: movie,
                                    watchlistIdentifier: watchlistIdentifier
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 4)

                    Spacer().frame(height: bottomSpacing)
                }
            }
        }
    }
}

private struct WatchlistItemView: View {

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
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .onTapGesture {
            presentedItem = .movie(movie)
        }
        .contextMenu {
            WatchlistOptions(
                presentedItem: $presentedItem,
                watchlistItemIdentifier: watchlistIdentifier
            )
        }
    }
}

#if DEBUG
struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 575265), state: .toWatch(info: .init(date: .now, suggestion: nil))),
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
