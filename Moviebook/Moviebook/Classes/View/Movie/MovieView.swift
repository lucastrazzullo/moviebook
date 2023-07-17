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

    @Binding private var navigationPath: NavigationPath

    @StateObject private var viewModel: MovieViewModel

    @State private var isVideoPresented: MovieVideo? = nil
    @State private var isErrorPresented: Bool = false

    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem?

    var body: some View {
        Group {
            if let movie = viewModel.movie {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: movie.details.title,
                    posterUrl: movie.details.media.posterUrl,
                    trailingHeaderView: { compact in
                        MovieTrailingHeaderView(
                            presentedItem: $presentedItem,
                            movieDetails: movie.details,
                            compact: compact
                        )
                    }, content: {
                        MovieContentView(
                            navigationPath: $navigationPath,
                            presentedItem: $presentedItem,
                            movie: movie,
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
            Navigation(path: $presentedItemNavigationPath, presentingItem: item)
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
}

private struct MovieTrailingHeaderView: View {

    @Binding var presentedItem: NavigationItem?

    let movieDetails: MovieDetails
    let compact: Bool

    var body: some View {
        if compact {
            Menu {
                WatchlistButton(
                    watchlistItemIdentifier: .movie(id: movieDetails.id),
                    watchlistItemReleaseDate: movieDetails.release,
                    presentedItem: $presentedItem) { state, _ in
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
                    watchlistItemReleaseDate: movieDetails.release,
                    presentedItem: $presentedItem) { state, _ in
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
