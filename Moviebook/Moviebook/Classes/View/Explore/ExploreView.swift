//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import MoviebookCommon

struct ExploreView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var discoverViewModel: DiscoverViewModel
    @StateObject private var discoverGenresViewModel: DiscoverGenresViewModel

    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem?

    private let stickyScrollingSpace: String = "stickyScrollingSpace"

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack {
                        if !searchViewModel.searchKeyword.isEmpty {
                            ExploreVerticalSectionView(
                                viewModel: searchViewModel.content,
                                presentedItem: $presentedItem
                            )
                        } else {
                            ExploreHorizontalMovieGenreSectionView(viewModel: discoverGenresViewModel)
                                .stickingToTop(coordinateSpaceName: stickyScrollingSpace)

                            VStack(spacing: 12) {
                                ForEach(discoverViewModel.sectionsContent) { content in
                                    ExploreHorizontalSectionView(
                                        viewModel: content,
                                        presentedItem: $presentedItem,
                                        geometry: geometry,
                                        viewAllDestination: {
                                            ScrollView {
                                                ExploreVerticalSectionView(
                                                    viewModel: content,
                                                    presentedItem: $presentedItem
                                                )
                                            }
                                            .scrollIndicators(.hidden)
                                            .navigationTitle(content.title)
                                            .toolbar {
                                                ToolbarItem(placement: .navigationBarTrailing) {
                                                    ExploreGenresPicker(viewModel: discoverGenresViewModel)
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
                .coordinateSpace(name: stickyScrollingSpace)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
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
                    ForEach(SearchViewModel.Search.Scope.allCases, id: \.self) { scope in
                        Text(scope.rawValue.capitalized)
                    }
                }
                .sheet(item: $presentedItem) { presentedItem in
                    Navigation(path: $presentedItemNavigationPath, presentingItem: presentedItem)
                }
                .onAppear {
                    discoverGenresViewModel.start(requestManager: requestManager)
                    searchViewModel.start(requestManager: requestManager)
                    discoverViewModel.start(selectedGenres: discoverGenresViewModel.selectedGenres, watchlist: watchlist, requestManager: requestManager)
                }
                .onChange(of: discoverGenresViewModel.selectedGenres) { selectedGenres in
                    discoverViewModel.update(selectedGenres: selectedGenres, requestManager: requestManager)
                }
            }
        }
    }

    init() {
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(scope: .movie, query: ""))
        self._discoverViewModel = StateObject(wrappedValue: DiscoverViewModel())
        self._discoverGenresViewModel = StateObject(wrappedValue: DiscoverGenresViewModel())
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environment(\.requestManager, MockRequestManager.shared)
            .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}
#endif
