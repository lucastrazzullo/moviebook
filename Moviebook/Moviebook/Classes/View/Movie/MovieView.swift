//
//  MovieView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/09/2022.
//

import SwiftUI

@MainActor private final class Content: ObservableObject {

    // MARK: Instance Properties

    @Published var movie: Movie?
    @Published var error: WebServiceError?

    private let movieId: Movie.ID

    // MARK: Object life cycle

    init(movieId: Movie.ID) {
        self.movieId = movieId
    }

    init(movie: Movie) {
        self.movieId = movie.id
        self.movie = movie
    }

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        guard movie == nil else { return }
        loadMovie(requestManager: requestManager)
    }

    private func loadMovie(requestManager: RequestManager) {
        Task {
            do {
                movie = try await MovieWebService(requestManager: requestManager).fetchMovie(with: movieId)
            } catch {
                self.error = .failedToLoad(id: .init(), retry: { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.loadMovie(requestManager: requestManager)
                    }
                })
            }
        }
    }
}

struct MovieView: View {

    @Environment(\.requestManager) var requestManager

    @Binding private var navigationPath: NavigationPath

    @StateObject private var content: Content

    @State private var isVideoPresented: MovieVideo? = nil
    @State private var isErrorPresented: Bool = false

    var body: some View {
        Group {
            if let movie = content.movie {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: movie.details.title,
                    posterUrl: movie.details.media.posterUrl,
                    trailingHeaderView: {
                        MovieTrailingHeaderView(movieId: movie.details.id,
                                                videos: movie.details.media.videos,
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
                content.error?.retry()
            }
        }
        .onChange(of: content.error) { error in
            isErrorPresented = error != nil
        }
        .onAppear {
            content.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(movieId: Movie.ID, navigationPath: Binding<NavigationPath>) {
        self._content = StateObject(wrappedValue: Content(movieId: movieId))
        self._navigationPath = navigationPath
    }

    init(movie: Movie, navigationPath: Binding<NavigationPath>) {
        self._content = StateObject(wrappedValue: Content(movie: movie))
        self._navigationPath = navigationPath
    }
}

private struct MovieTrailingHeaderView: View {

    let movieId: Movie.ID
    let videos: [MovieVideo]
    let onSelected: (MovieVideo) -> Void

    var body: some View {
        WatermarkView {
            IconWatchlistButton(watchlistItem: .movie(id: movieId))

            if !videos.isEmpty {
                TrailerMenu(videos: videos) { video in
                    onSelected(video)
                }
            }
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
            MovieView(movieId: 954, navigationPath: .constant(NavigationPath()))
                .environmentObject(Watchlist(inMemoryItems: [
                    .movie(id: 954): .toWatch(reason: .suggestion(from: "Valerio", comment: "This is really nice"))
                ]))
                .environment(\.requestManager, MockRequestManager())
        }
    }
}
#endif
