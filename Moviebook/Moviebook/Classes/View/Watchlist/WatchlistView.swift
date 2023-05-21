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

    @StateObject private var viewModel: WatchlistViewModel = WatchlistViewModel()
    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if viewModel.isLoading {
                    LoaderView()
                } else if viewModel.items.isEmpty {
                    EmptyWatchlistView(
                        section: $viewModel.currentSection,
                        onStartDiscoverySelected: { presentedItem = .explore }
                    )
                } else {
                    ListView(
                        viewModel: viewModel,
                        onMovieSelected: { movie in presentedItem = .movie(movie) }
                    )
                }
            }
        }
        .watchlistPrompt(duration: 5)
        .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
        .toolbar {
            makeSectionSelectionToolbarItem()
            makeExploreToolbarItem()
        }
        .sheet(item: $presentedItem) { item in
            Navigation(path: $presentedItemNavigationPath, presentingItem: item)
        }
        .onAppear {
            viewModel.start(watchlist: watchlist, requestManager: requestManager)
        }
    }

    // MARK: Private factory methods

    @ToolbarContentBuilder private func makeExploreToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            WatermarkView {
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        presentedItem = .explore
                    }
            }
        }
    }

    @ToolbarContentBuilder private func makeSectionSelectionToolbarItem() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Picker("Section", selection: $viewModel.currentSection) {
                ForEach(viewModel.sectionIdentifiers, id: \.self) { section in
                    Text(section.name)
                }
            }
            .segmentedStyled()
        }
    }
}

private struct ListView: View {

    @EnvironmentObject var watchlist: Watchlist

    @ObservedObject var viewModel: WatchlistViewModel

    let onMovieSelected: (Movie) -> Void

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                switch item {
                case .movie(let movie, _, let watchlistIdentifier):
                    MoviePreviewView(details: movie.details) {
                        onMovieSelected(movie)
                    }
                    .swipeActions {
                        Button(action: { watchlist.remove(itemWith: watchlistIdentifier) }) {
                            HStack {
                                Image(systemName: "minus")
                                Text("Remove")
                            }
                        }
                        .tint(Color.accentColor)
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
    }
}

private struct UndoView: View {

    let itemToRemove: WatchlistViewModel.SectionItem
    let timeRemaining: TimeInterval
    let action: () -> Void

    var body: some View {
        switch itemToRemove {
        case .movie(let movie, let section, _):
            HStack(spacing: 24) {
                HStack {
                    AsyncImage(url: movie.details.media.posterPreviewUrl) { image in
                        image.resizable().aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(width: 60)
                    .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text("Removed from \(section.name)")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        Text(movie.details.title)
                            .lineLimit(2)
                            .font(.headline)
                    }
                }

                Spacer()

                Button(action: action) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Undo")
                        ProgressView(value: max(0, timeRemaining), total: 5)
                            .progressViewStyle(.linear)
                            .animation(.linear, value: timeRemaining)
                    }
                }
                .tint(Color.accentColor)
                .fixedSize()
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .padding()
            .background(Rectangle().fill(.background))
        }
    }
}

#if DEBUG
struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            WatchlistView()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: nil), date: .now)))
                ]))
        }

        NavigationView {
            WatchlistView()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
                ]))
        }

        NavigationView {
            WatchlistView()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: []))
        }
    }
}
#endif
