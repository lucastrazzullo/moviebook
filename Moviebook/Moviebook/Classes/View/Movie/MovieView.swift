//
//  MovieView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/09/2022.
//

import SwiftUI

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
                        MovieTrailingHeaderView(movieDetails: movie.details,
                                                onSelected: { video in
                            isVideoPresented = video
                        })
                    }, content: {
                        MovieContentView(navigationPath: $navigationPath, movie: movie)
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

                WatermarkView {
                    Button(action: { isVideoPresented = nil }) {
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
    let onSelected: (MovieVideo) -> Void

    var body: some View {
        WatermarkView {
            IconWatchlistButton(watchlistItem: .movie(id: movieDetails.id))
            ShareButton(movieDetails: movieDetails)

            if !movieDetails.media.videos.isEmpty {
                TrailerMenu(videos: movieDetails.media.videos) { video in
                    onSelected(video)
                }
            }
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

private struct TrailerMenu: View {

    let videos: [MovieVideo]
    let onSelected: (MovieVideo) -> Void

    var body: some View {
        Menu {
            ForEach(videos) { video in
                Button(action: { onSelected(video) }) {
                    HStack {
                        switch video.type {
                        case .trailer:
                            Text("Trailer: \(video.name)")
                        case .teaser:
                            Text("Teaser: \(video.name)")
                        case .behindTheScenes:
                            Text("Behind the scenes: \(video.name)")
                        }
                        Spacer()
                        Image(systemName: "play")
                    }
                }
            }
        } label: {
            Image(systemName: "play.fill")
        }
    }
}

#if DEBUG
struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 353081, navigationPath: .constant(NavigationPath()))
                .environmentObject(Watchlist(inMemoryItems: [
                    .movie(id: 353081): .toWatch(reason: .suggestion(from: "Valerio", comment: "This is really nice"))
                ]))
                .environment(\.requestManager, MockRequestManager())
        }
    }
}
#endif
