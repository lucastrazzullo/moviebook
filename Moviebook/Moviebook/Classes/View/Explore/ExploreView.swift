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

    @StateObject private var searchViewModel: ExploreSearchViewModel
    @StateObject private var exploreViewModel: ExploreSectionViewModel

    @State private var presentedItem: PresentingItem?
    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()

    var body: some View {
        NavigationView {
            List {
                if !searchViewModel.searchKeyword.isEmpty {
                    SectionView(
                        title: searchViewModel.title,
                        isLoading: searchViewModel.isLoading,
                        error: searchViewModel.error,
                        loadMore: searchViewModel.fetchNextPage) {
                            switch searchViewModel.result {
                            case .movies(let movies):
                                ForEach(movies, id: \.self) { movieDetails in
                                    MoviePreviewView(details: movieDetails) {
                                        presentedItem = .movie(movieId: movieDetails.id)
                                    }
                                }
                            case .artists(let artists):
                                ForEach(artists, id: \.self) { artistDetails in
                                    ArtistPreviewView(details: artistDetails) {
                                        presentedItem = .artist(artistId: artistDetails.id)
                                    }
                                }
                            }
                        }
                } else {
                    ForEach(exploreViewModel.sections) { section in
                        SectionView(
                            title: section.name,
                            isLoading: section.isLoading,
                            error: section.error,
                            loadMore: nil) {
                                ForEach(section.items, id: \.self) { movieDetails in
                                    MoviePreviewView(details: movieDetails) {
                                        presentedItem = .movie(movieId: movieDetails.id)
                                    }
                                }
                            }
                    }
                }
            }
            .listStyle(.inset)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
            .toolbar {
                ToolbarItem {
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
                ForEach(ExploreSearchViewModel.Scope.allCases, id: \.self) { scope in
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

    init(searchScope: ExploreSearchViewModel.Scope, searchQuery: String?) {
        self._searchViewModel = StateObject(wrappedValue: ExploreSearchViewModel(scope: searchScope, query: searchQuery))
        self._exploreViewModel = StateObject(wrappedValue: ExploreSectionViewModel())
    }
}

private struct SectionView<Content: View>: View {

    let title: String
    let isLoading: Bool
    let error: WebServiceError?
    let loadMore: (() -> Void)?

    @ViewBuilder let content: () -> Content

    var body: some View {
        Section(header: HeaderView(title: title, isLoading: isLoading)) {
            if let error {
                ErrorView(error: error)
            }

            content()

            if let loadMore {
                LoadMoreView(action: loadMore)
            }
        }
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
    }
}

private struct HeaderView: View {

    let title: String
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .foregroundColor(.primary)

            if isLoading {
                ProgressView()
            }
        }
    }
}

private struct LoadMoreView: View {

    let action: () -> Void

    var body: some View {
        Group {
            Button(action: action) {
                HStack {
                    Text("Load more")
                    Image(systemName: "arrow.down.square.fill")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

private struct ErrorView: View {

    let error: WebServiceError

    var body: some View {
        VStack {
            Text("Something went wrong")
                .foregroundColor(.primary)
                .underline()

            Button(action: error.retry) {
                Text("Retry")
            }
            .buttonStyle(.borderless)
        }
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

            List {
                Section {
                    LoadMoreView(action: {})
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }
            .listStyle(.inset)
        }
    }
}
#endif
