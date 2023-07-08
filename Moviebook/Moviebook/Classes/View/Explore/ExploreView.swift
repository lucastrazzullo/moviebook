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

    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem?

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                List {
                    if !searchViewModel.searchKeyword.isEmpty {
                        ExploreVerticalSectionView(
                            viewModel: searchViewModel.content,
                            presentedItem: $presentedItem
                        )
                    } else {
                        ExploreHorizontalMovieGenreSectionView(selectedGenre: $discoverViewModel.genre)

                        ForEach(discoverViewModel.sectionsContent) { content in
                            ExploreHorizontalSectionView(
                                viewModel: content,
                                presentedItem: $presentedItem,
                                pageWidth: geometry.size.width,
                                viewAllDestination: {
                                    List {
                                        ExploreVerticalSectionView(
                                            viewModel: content,
                                            presentedItem: $presentedItem
                                        )
                                    }
                                    .listStyle(.inset)
                                    .scrollIndicators(.hidden)
                                    .navigationTitle(content.title + " " + (discoverViewModel.genre?.name ?? ""))
                                }
                            )
                        }
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.immediately)
                .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: dismiss.callAsFunction) {
                            Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        VStack {
                            if let genre = discoverViewModel.genre {
                                Button(action: { self.discoverViewModel.genre = nil }) {
                                    HStack {
                                        Image(systemName: "x.square.fill")
                                        Text(genre.name)
                                    }
                                }
                                .buttonStyle(OvalButtonStyle(.small))
                            }
                        }
                        .animation(.default, value: discoverViewModel.genre)
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
                    searchViewModel.start(requestManager: requestManager)
                    discoverViewModel.start(requestManager: requestManager)
                }
            }
        }
    }

    init() {
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(scope: .movie, query: ""))
        self._discoverViewModel = StateObject(wrappedValue: DiscoverViewModel())
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreView()
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
                ]))
        }
    }
}
#endif
