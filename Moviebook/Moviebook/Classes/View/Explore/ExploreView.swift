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
    @StateObject private var movieGenresViewModel: MovieGenresViewModel

    @State private var started: Bool = false
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
                                onItemSelected: { item in
                                    presentedItem = item
                                }
                            )
                        } else {
                            ExploreHorizontalMovieGenreSectionView(viewModel: movieGenresViewModel)
                                .stickingToTop(coordinateSpaceName: stickyScrollingSpace)

                            VStack(spacing: 12) {
                                ForEach(discoverViewModel.sectionsContent) { content in
                                    ExploreHorizontalSectionView(
                                        viewModel: content,
                                        layout: content.dataProvider is DiscoverRelated ? .shelf : .multirows,
                                        containerWidth: geometry.size.width,
                                        onItemSelected: { item in
                                            presentedItem = item
                                        },
                                        viewAllDestination: {
                                            ScrollView(showsIndicators: false) {
                                                ExploreVerticalSectionView(
                                                    viewModel: content,
                                                    onItemSelected: { item in
                                                        presentedItem = item
                                                    }
                                                )
                                            }
                                            .navigationTitle(content.title)
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
                    ForEach(SearchDataProvider.Scope.allCases, id: \.self) { scope in
                        Text(scope.rawValue.capitalized)
                    }
                }
                .sheet(item: $presentedItem) { presentedItem in
                    Navigation(rootItem: presentedItem)
                }
                .onAppear {
                    if !started {
                        started = true
                        movieGenresViewModel.start(requestManager: requestManager)
                        searchViewModel.start(requestManager: requestManager)
                        discoverViewModel.start(selectedGenres: movieGenresViewModel.$selectedGenres, watchlist: watchlist, requestManager: requestManager)
                    }
                }
            }
        }
    }

    init() {
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(scope: .movie, query: ""))
        self._discoverViewModel = StateObject(wrappedValue: DiscoverViewModel())
        self._movieGenresViewModel = StateObject(wrappedValue: MovieGenresViewModel())
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
