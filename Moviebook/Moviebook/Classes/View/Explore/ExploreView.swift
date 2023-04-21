//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct ExploreView: View {

    private struct MovieIdentifier: Identifiable {
        let id: Movie.ID
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var searchContent: ExploreSearchContent = ExploreSearchContent()
    @StateObject private var exploreContent: ExploreSectionContent = ExploreSectionContent()

    @State private var movieNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedMovieIdentifier: MovieIdentifier?

    var body: some View {
        NavigationView {
            List {
                if searchContent.isLoading || !searchContent.searchKeyword.isEmpty {
                    SectionView(title: searchContent.title,
                                isLoading: searchContent.isLoading,
                                error: searchContent.error,
                                items: searchContent.result,
                                onMovieSelected: { movieIdentifier in
                        presentedMovieIdentifier = MovieIdentifier(id: movieIdentifier)
                    })
                }

                ForEach(exploreContent.sections) { section in
                    SectionView(title: section.name,
                                isLoading: section.isLoading,
                                error: section.error,
                                items: .movies(section.items),
                                onMovieSelected: { movieIdentifier in
                        presentedMovieIdentifier = MovieIdentifier(id: movieIdentifier)
                    })
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
            .sheet(item: $presentedMovieIdentifier) { movieIdentifier in
                NavigationStack(path: $movieNavigationPath) {
                    MovieView(movieId: movieIdentifier.id, navigationPath: $movieNavigationPath)
                        .navigationDestination(for: Movie.ID.self) { movieId in
                            MovieView(movieId: movieId, navigationPath: $movieNavigationPath)
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
                    ArtistPreviewView(details: artistDetails)
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
