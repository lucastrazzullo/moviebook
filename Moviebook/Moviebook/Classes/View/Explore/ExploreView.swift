//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import MoviebookCommon

struct ExploreView: View {

    private let stickyScrollingSpace: String = "stickyScrollingSpace"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var filtersViewModel: ExploreFiltersViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var discoverViewModel: DiscoverViewModel

    @State private var started: Bool = false

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        if !searchViewModel.searchKeyword.isEmpty {
                            ExploreVerticalSectionView(
                                viewModel: searchViewModel.content,
                                onItemSelected: onItemSelected
                            )
                        } else {
                            ExploreFiltersView(
                                viewModel: filtersViewModel
                            )
                            .stickingToTop(coordinateSpaceName: stickyScrollingSpace)

                            ExploreSections(
                                discoverViewModel: discoverViewModel,
                                containerWidth:  geometry.size.width,
                                onItemSelected: onItemSelected
                            )
                        }
                    }
                }
                .coordinateSpace(name: stickyScrollingSpace)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: dismiss.callAsFunction) {
                            Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                        }
                    }
                }
                .searchable(
                    text: $searchViewModel.searchKeyword,
                    prompt: NSLocalizedString("EXPLORE.SEARCH.PROMPT", comment: "")
                )
                .searchScopes($searchViewModel.searchScope) {
                    ForEach(SearchDataProvider.Scope.allCases, id: \.self) { scope in
                        Text(scope.rawValue.capitalized)
                    }
                }
                .onAppear {
                    if !started {
                        started = true
                        filtersViewModel.start(requestLoader: requestLoader)
                        searchViewModel.start(requestLoader: requestLoader)
                        discoverViewModel.start(
                            selectedGenres: filtersViewModel.$selectedGenres,
                            selectedYear: filtersViewModel.$selectedYear,
                            watchlist: watchlist,
                            requestLoader: requestLoader
                        )
                    }
                }
            }
        }
    }

    init(selectedGenres: Set<MovieGenre>, onItemSelected: @escaping (NavigationItem) -> Void) {
        self._filtersViewModel = StateObject(wrappedValue: ExploreFiltersViewModel(selectedGenres: selectedGenres))
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(scope: .movie, query: ""))
        self._discoverViewModel = StateObject(wrappedValue: DiscoverViewModel())
        self.onItemSelected = onItemSelected
    }
}

private struct ExploreSections: View {

    @ObservedObject var discoverViewModel: DiscoverViewModel

    let containerWidth: CGFloat
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(discoverViewModel.sectionsContent) { content in
                ExploreHorizontalSectionView(
                    viewModel: content,
                    layout: content.dataProvider is DiscoverRelated ? .shelf : .multirows,
                    containerWidth: containerWidth,
                    onItemSelected: onItemSelected,
                    viewAllDestination: {
                        ScrollView(showsIndicators: false) {
                            ExploreVerticalSectionView(
                                viewModel: content,
                                onItemSelected: onItemSelected
                            )
                        }
                        .navigationTitle(content.title)
                    }
                )
            }
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView(
            selectedGenres: [],
            onItemSelected: { _ in }
        )
        .environment(\.requestLoader, MockRequestLoader.shared)
        .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}
#endif
