//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct ExploreView: View {

    private enum PresentingItem: Identifiable {
        case movie(movieId: Movie.ID)
        case artist(artistId: Artist.ID)

        var id: AnyHashable {
            switch self {
            case .movie(let movieId):
                return movieId
            case .artist(let artistId):
                return artistId
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var exploreViewModel: ExploreViewModel

    @State private var presentedItem: PresentingItem?
    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()

    var body: some View {
        NavigationView {
            List {
                if !searchViewModel.searchKeyword.isEmpty {
                    ExploreVerticalSectionView(viewModel: searchViewModel.content, onItemSelected: { movieId in
                        presentedItem = .movie(movieId: movieId)
                    })
                } else {
                    ForEach(exploreViewModel.sections) { sectionViewModel in
                        ExploreHorizontalSectionView(viewModel: sectionViewModel) { movieId in
                            presentedItem = .movie(movieId: movieId)
                        }
                    }
                }
            }
            .listStyle(.inset)
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
                ForEach(SearchViewModel.Scope.allCases, id: \.self) { scope in
                    Text(scope.rawValue.capitalized)
                }
            }
            .sheet(item: $presentedItem) { presentedItem in
                NavigationStack(path: $presentedItemNavigationPath) {
                    Group {
                        switch presentedItem {
                        case .movie(let movieIdentifier):
                            MovieView(movieId: movieIdentifier, navigationPath: $presentedItemNavigationPath)
                        case .artist(let artistIdentifier):
                            ArtistView(artistId: artistIdentifier, navigationPath: $presentedItemNavigationPath)
                        }
                    }
                    .navigationDestination(for: NavigationItem.self) { item in
                        NavigationDestination(navigationPath: $presentedItemNavigationPath, item: item)
                    }
                }

            }
            .onAppear {
                searchViewModel.start(requestManager: requestManager)
                exploreViewModel.start(requestManager: requestManager)
            }
        }
    }

    init(searchScope: SearchViewModel.Scope, searchQuery: String?) {
        self._searchViewModel = StateObject(wrappedValue: SearchViewModel(scope: searchScope, query: searchQuery))
        self._exploreViewModel = StateObject(wrappedValue: ExploreViewModel())
    }
}

#if DEBUG
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreView(searchScope: .movie, searchQuery: nil)
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
                ]))
        }
    }
}
#endif
