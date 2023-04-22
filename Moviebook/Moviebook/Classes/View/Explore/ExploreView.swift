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

        var id: Int {
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

    @StateObject private var searchContent: ExploreSearchContent = ExploreSearchContent()
    @StateObject private var exploreContent: ExploreSectionContent = ExploreSectionContent()

    @State private var presentedItem: PresentingItem?
    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()

    var body: some View {
        NavigationView {
            List {
                if searchContent.isLoading || !searchContent.searchKeyword.isEmpty {
                    SectionView(title: searchContent.title,
                                isLoading: searchContent.isLoading,
                                error: searchContent.error,
                                items: searchContent.result,
                                onMovieSelected: { movieIdentifier in
                                    presentedItem = .movie(movieId: movieIdentifier)
                                },
                                onArtistSelected: { artistIdentifier in
                                    presentedItem = .artist(artistId: artistIdentifier)
                                }
                    )
                }

                ForEach(exploreContent.sections) { section in
                    SectionView(title: section.name,
                                isLoading: section.isLoading,
                                error: section.error,
                                items: .movies(section.items),
                                onMovieSelected: { movieIdentifier in
                                    presentedItem = .movie(movieId: movieIdentifier)
                                },
                                onArtistSelected: { artistIdentifier in
                                    presentedItem = .artist(artistId: artistIdentifier)
                                }
                    )
                }
                .listSectionSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
            .toolbar {
                ToolbarItem {
                    Button(action: dismiss.callAsFunction) {
                        Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                    }
                }
            }
            .searchable(
                text: $searchContent.searchKeyword,
                prompt: NSLocalizedString("EXPLORE.SEARCH.PROMPT", comment: "")
            )
            .searchScopes($searchContent.searchScope) {
                ForEach(ExploreSearchContent.Scope.allCases, id: \.self) { scope in
                    Text(scope.rawValue.capitalized)
                }
            }
            .sheet(item: $presentedItem) { presentedItem in
                NavigationStack(path: $presentedItemNavigationPath) {
                    switch presentedItem {
                    case .movie(let movieIdentifier):
                        MovieView(movieId: movieIdentifier, navigationPath: $presentedItemNavigationPath)
                            .navigationDestination(for: Movie.ID.self) { movieId in
                                MovieView(movieId: movieId, navigationPath: $presentedItemNavigationPath)
                            }
                    case .artist(let artistIdentifier):
                        ArtistView(artistId: artistIdentifier, navigationPath: $presentedItemNavigationPath)
                            .navigationDestination(for: Movie.ID.self) { movieId in
                                MovieView(movieId: movieId, navigationPath: $presentedItemNavigationPath)
                            }
                    }
                }

            }
            .onAppear {
                searchContent.start(requestManager: requestManager)
                exploreContent.start(requestManager: requestManager)
            }
        }
    }
}

private struct SectionView: View {

    let title: String
    let isLoading: Bool
    let error: WebServiceError?
    let items: ExploreListItems
    let onMovieSelected: (Movie.ID) -> Void
    let onArtistSelected: (Artist.ID) -> Void

    var body: some View {
        Section(header: header) {
            switch items {
            case .movies(let movies):
                ForEach(movies, id: \.self) { movieDetails in
                    MoviePreviewView(details: movieDetails) {
                        onMovieSelected(movieDetails.id)
                    }
                }
            case .artists(let artists):
                ForEach(artists, id: \.self) { artistDetails in
                    ArtistPreviewView(details: artistDetails) {
                        onArtistSelected(artistDetails.id)
                    }
                }
            }
        }
        .listSectionSeparator(.hidden)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .foregroundColor(.primary)

            if isLoading {
                ProgressView()
            }
            if let error = error {
                HStack {
                    Spacer()
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
    }
}

#if DEBUG
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreView()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    .movie(id: 954): .toWatch(reason: .none),
                    .movie(id: 616037): .toWatch(reason: .none)
                ]))
        }
    }
}
#endif
