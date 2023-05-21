//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct ExploreView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var exploreViewModel: ExploreViewModel

    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem?

    var body: some View {
        NavigationView {
            List {
                if !searchViewModel.dataProvider.searchKeyword.isEmpty {
                    ExploreVerticalSectionView(viewModel: searchViewModel.content, presentedItem: $presentedItem)
                } else {
                    ForEach(exploreViewModel.sections) { sectionViewModel in
                        ExploreHorizontalSectionView(viewModel: sectionViewModel, presentedItem: $presentedItem)
                    }
                }
            }
            .listStyle(.inset)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            .watchlistPrompt(duration: 5)
            .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: dismiss.callAsFunction) {
                        Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                    }
                }
            }
            .searchable(
                text: $searchViewModel.dataProvider.searchKeyword,
                prompt: NSLocalizedString("EXPLORE.SEARCH.PROMPT", comment: "")
            )
            .searchScopes($searchViewModel.dataProvider.searchScope) {
                ForEach(SearchViewModel.DataProvider.Scope.allCases, id: \.self) { scope in
                    Text(scope.rawValue.capitalized)
                }
            }
            .sheet(item: $presentedItem) { presentedItem in
                Navigation(path: $presentedItemNavigationPath, presentingItem: presentedItem)
            }
            .onAppear {
                searchViewModel.start(requestManager: requestManager)
                exploreViewModel.start(requestManager: requestManager)
            }
        }
    }

    init() {
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(scope: .movie, query: nil))
        self._exploreViewModel = StateObject(wrappedValue: ExploreViewModel())
    }
}

#if DEBUG
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreView()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
                ]))
        }
    }
}
#endif
