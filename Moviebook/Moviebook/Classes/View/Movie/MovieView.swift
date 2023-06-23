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

    var body: some View {
        Group {
            if let movie = viewModel.movie {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: movie.details.title,
                    posterUrl: movie.details.media.posterUrl,
                    trailingHeaderView: {
                        MovieTrailingHeaderView(
                            movieDetails: movie.details
                        )
                    }, content: {
                        MovieContentView(
                            navigationPath: $navigationPath,
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
                    WatermarkView {
                        Image(systemName: "chevron.down")
                    }
                }
                .padding()
            }
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

    init(movie: Movie, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: MovieViewModel(movie: movie))
        self._navigationPath = navigationPath
    }
}

private struct MovieTrailingHeaderView: View {

    let movieDetails: MovieDetails

    var body: some View {
        WatermarkView {
            IconWatchlistButton(watchlistItemIdentifier: .movie(id: movieDetails.id))
            ShareButton(movieDetails: movieDetails)
        }
    }
}

private struct ShareButton: View {

    let movieDetails: MovieDetails

    var body: some View {
        ShareLink(item: Deeplink.movie(identifier: movieDetails.id).rawValue) {
            Image(systemName: "square.and.arrow.up")
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 353081, navigationPath: .constant(NavigationPath()))
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "This is really nice"))))
                ]))
                .environment(\.requestManager, MockRequestManager.shared)
        }
    }
}
#endif
