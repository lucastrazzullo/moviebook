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
                    VStack(spacing: 24) {
                        if !searchViewModel.searchKeyword.isEmpty {
                            ExploreVerticalSectionView(
                                viewModel: searchViewModel.content,
                                presentedItem: $presentedItem
                            )
                        } else {
                            ExploreHorizontalMovieGenreSectionView(
                                selectedGenre: $discoverViewModel.genre,
                                genres: discoverGenresViewModel.genres
                            )
                            .stickingToTop(coordinateSpaceName: stickyScrollingSpace)

                            LazyVStack {
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
                                                    GenresPicker(
                                                        selectedGenre: $discoverViewModel.genre,
                                                        genres: discoverGenresViewModel.genres
                                                    )
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
                    searchViewModel.start(requestManager: requestManager)
                    discoverViewModel.start(requestManager: requestManager)
                    discoverGenresViewModel.start(requestManager: requestManager)
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

private struct GenresPicker: View {

    @Binding var selectedGenre: MovieGenre?

    let genres: [MovieGenre]

    var body: some View {
        if let selectedGenre {
            Menu {
                Button(role: .destructive) { self.selectedGenre = nil } label: {
                    Text("Remove filter")
                    Image(systemName: "xmark")
                }

                ForEach(genres, id: \.self) { genre in
                    Button { self.selectedGenre = genre } label: {
                        Text(genre.name)
                        if selectedGenre == genre {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack {
                    Text(selectedGenre.name)
                    Image(systemName: "chevron.up.chevron.down")
                }
                .font(.caption.bold())
                .foregroundColor(.black)
                .padding(6)
                .background(.yellow, in: RoundedRectangle(cornerRadius: 10))
            }
        }
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
