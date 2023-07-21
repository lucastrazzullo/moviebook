//
//  MovieView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/09/2022.
//

import SwiftUI
import MoviebookCommon

struct MovieView: View {

    @Environment(\.requestManager) var requestManager

    @StateObject private var viewModel: MovieViewModel

    @Binding private var navigationPath: NavigationPath
    @State private var presentedItem: NavigationItem?

    @State private var isVideoPresented: MovieVideo? = nil
    @State private var isErrorPresented: Bool = false

    var body: some View {
        Group {
            if let movie = viewModel.movie {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: movie.details.title,
                    posterUrl: movie.details.media.posterUrl,
                    trailingHeaderView: { compact in
                        MovieTrailingHeaderView(
                            movieDetails: movie.details,
                            compact: compact,
                            onItemSelected: presentItem
                        )
                    }, content: {
                        MovieContentView(
                            movie: movie,
                            onItemSelected: presentItem,
                            onVideoSelected: { video in
                                isVideoPresented = video
                            }
                        )
                    }
                )
            } else {
                LoaderView()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .fullScreenCover(item: $isVideoPresented) { video in
            ZStack(alignment: .topLeading) {
                MovieVideoPlayer(video: video, autoplay: true)

                Button(action: { isVideoPresented = nil }) {
                    Image(systemName: "chevron.down")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(OvalButtonStyle(.normal))
                .padding()
            }
        }
        .sheet(item: $presentedItem) { item in
            Navigation(rootItem: item)
        }
        .alert("Error", isPresented: $isErrorPresented) {
            Button("Retry", role: .cancel) {
                viewModel.error?.retry()
            }
        }
        .onChange(of: viewModel.error) { error in
            isErrorPresented = error != nil
        }
        .onAppear {
            viewModel.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(movieId: Movie.ID, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: MovieViewModel(movieId: movieId))
        self._navigationPath = navigationPath
    }

    // MARK: Private methods

    private func presentItem(_ item: NavigationItem) {
        switch item {
        case .explore, .movieWithIdentifier, .artistWithIdentifier:
            navigationPath.append(item)
        case .watchlistAddToWatchReason, .watchlistAddRating:
            presentedItem = item
        }
    }
}

private struct MovieTrailingHeaderView: View {

    let movieDetails: MovieDetails
    let compact: Bool
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        if compact {
            Menu {
                WatchlistButton(
                    watchlistItemIdentifier: .movie(id: movieDetails.id),
                    watchlistItemReleaseDate: movieDetails.localisedReleaseDate(),
                    onItemSelected: onItemSelected) { state, _ in
                    WatchlistLabel(itemState: state)
                    WatchlistIcon(itemState: state)
                }

                ShareButton(movieDetails: movieDetails)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 18, height: 18, alignment: .center)
            }
        } else {
            HStack(spacing: 18) {
                WatchlistButton(
                    watchlistItemIdentifier: .movie(id: movieDetails.id),
                    watchlistItemReleaseDate: movieDetails.localisedReleaseDate(),
                    onItemSelected: onItemSelected) { state, _ in
                    WatchlistIcon(itemState: state)
                        .frame(width: 16, height: 16, alignment: .center)
                        .padding(4)
                }

                ShareButton(movieDetails: movieDetails)
                    .frame(width: 16, height: 16, alignment: .center)
                    .padding(4)
            }
        }
    }
}

private struct ShareButton: View {

    let movieDetails: MovieDetails

    var body: some View {
        ShareLink(item: Deeplink.movie(identifier: movieDetails.id).rawValue) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 353081, navigationPath: .constant(NavigationPath()))
                .environmentObject(MockWatchlistProvider.shared.watchlist())
                .environment(\.requestManager, MockRequestManager.shared)
        }
    }
}
#endif
