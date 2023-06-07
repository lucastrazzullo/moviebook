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

    var body: some View {
        TabView(selection: $currentSection) {
            Group {
                ForEach(WatchlistViewModel.Section.allCases) { section in
                    ContentView(
                        presentedItem: $presentedItem,
                        section: section
                    )
                    .tag(section)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
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

    let section: WatchlistViewModel.Section

    var body: some View {
        GeometryReader { geometry in
            let bottomSpacing = geometry.safeAreaInsets.bottom + 32
            Group {
                if viewModel.isLoading {
                    LoaderView()
                } else if viewModel.items.isEmpty {
                    EmptyWatchlistView(section: section)
                        .padding(.bottom, bottomSpacing)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            WatchlistListView(
                                presentedItem: $presentedItem,
                                section: section,
                                items: viewModel.items
                            )
                            .padding(.horizontal, 4)

                            Spacer().frame(height: bottomSpacing)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.start(section: section, watchlist: watchlist, requestManager: requestManager)
            }
        }
    }
}

private struct WatchlistListView: View {

    @Binding var presentedItem: NavigationItem?

    let section: WatchlistViewModel.Section
    let items: [WatchlistViewModel.Item]

    var body: some View {
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
    }
}

private struct WatchlistItemView: View {

    @Binding var presentedItem: NavigationItem?

    let movie: Movie
    let watchlistIdentifier: WatchlistItemIdentifier

    var body: some View {
        Group {
            AsyncImage(url: movie.details.media.posterPreviewUrl, content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }, placeholder: {
                Color
                    .gray
                    .opacity(0.2)
            })
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .onTapGesture {
            presentedItem = .movie(movie)
        }
        .contextMenu {
            WatchlistOptions(
                watchlistItemIdentifier: watchlistIdentifier,
                onAddToWatchReason: {
                    presentedItem = .watchlistAddToWatchReason(itemIdentifier: watchlistIdentifier)
                },
                onAddRating: {
                    presentedItem = .watchlistAddRating(itemIdentifier: watchlistIdentifier)
                }
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
