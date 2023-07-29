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
            } else if viewModel.items(in: section).isEmpty {
                EmptyListView(
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    section: section
                )
            } else {
                ScrollingListView(
                    shouldShowTopBar: $shouldShowTopBar,
                    shouldShowBottomBar: $shouldShowBottomBar,
                    section: section,
                    items: viewModel.items(in: section),
                    onItemSelected: onItemSelected
                )
            }
        }
    }
}

private struct EmptyListView: View {

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewSection

    var body: some View {
        EmptyWatchlistView(section: section)
            .background(.thinMaterial)
            .onAppear {
                shouldShowTopBar = false
                shouldShowBottomBar = false
            }
    }
}

private struct ScrollingListView: View {

    @State private var scrollContent: ObservableScrollContent = .zero

    @Binding var shouldShowTopBar: Bool
    @Binding var shouldShowBottomBar: Bool

    let section: WatchlistViewSection
    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        GeometryReader { geometry in
            ObservableScrollView(scrollContent: $scrollContent, showsIndicators: false) { _ in
                VStack {
                    if case .watched = section {
                        StatsView(
                            items: items,
                            onItemSelected: onItemSelected
                        )
                    }

                    ListView(
                        items: items,
                        onItemSelected: onItemSelected
                    )
                }
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
        shouldShowTopBar = scrollContent.offset > 0 + 10
        shouldShowBottomBar = -(scrollContent.offset - scrollContent.height) > geometry.size.height + 20
    }
}

private struct ListView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack {
            ForEach(items) { item in
                WatchlistItemView(
                    item: item,
                    onItemSelected: onItemSelected
                )
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct WatchlistItemView: View {

    let item: WatchlistViewItem
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        switch item {
        case .movie(let movie, _):
            ZStack(alignment: .bottom) {
                RemoteImage(url: movie.details.media.backdropUrl, content: { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                }, placeholder: {
                    Rectangle().fill(.gray)
                })
                .padding(.bottom, 100)

                HStack(alignment: .lastTextBaseline) {
                    VStack(alignment: .leading) {
                        Text(movie.details.title)
                            .font(.headline)
                            .lineLimit(3)

                        if movie.details.localisedReleaseDate() > .now {
                            Text("Coming on \(movie.details.localisedReleaseDate().formatted(.dateTime.year()))")
                                .bold()
                                .padding(4)
                                .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                                .foregroundColor(.black)
                                .font(.caption)
                        } else {
                            Text(movie.details.localisedReleaseDate(), format: .dateTime.year())
                                .font(.caption)
                        }

                        RatingView(rating: movie.details.rating)
                            .padding(.top, 4)
                    }

                    Spacer()

                    IconWatchlistButton(
                        watchlistItemIdentifier: .movie(id: movie.id),
                        watchlistItemReleaseDate: movie.details.localisedReleaseDate(),
                        onItemSelected: onItemSelected
                    )
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thickMaterial)
            }
            .cornerRadius(12)
            .onTapGesture {
                onItemSelected(.movieWithIdentifier(movie.id))
            }
        }
    }
}

private struct StatsView: View {

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if totalNumberOfWatchedHours > 0 || popularGenres.count > 0 {
            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.largeTitle)
                    Text("Stats")
                        .font(.title2)
                }

                if totalNumberOfWatchedHours > 0 {
                    VStack(spacing: 4) {
                        Text("Total time watched")
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
            case .movie(let movie, _):
                return total + (movie.details.runtime ?? 0)
            }
        })
    }

    private var popularGenres: [MovieGenre] {
        return items
            .reduce([MovieGenre]()) { list, item in
                switch item {
                case .movie(let movie, _):
                    return list + movie.genres
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
