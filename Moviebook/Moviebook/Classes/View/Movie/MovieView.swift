//
//  MovieView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/09/2022.
//

import SwiftUI

@MainActor private final class Content: ObservableObject {

    // MARK: Types

    enum Error: Swift.Error, Equatable {
        case failedToLoad
    }

    // MARK: Instance Properties

    @Published var movie: Movie?
    @Published var error: Error?

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

    func start(requestManager: RequestManager) async {
        guard movie == nil else { return }

        do {
            movie = try await MovieWebService(requestManager: requestManager).fetchMovie(with: movieId)
        } catch {
            self.error = .failedToLoad
        }
    }
}

struct MovieView: View {

    @Environment(\.requestManager) var requestManager

    @Binding private var navigationPath: NavigationPath

    @StateObject private var content: Content
    @State private var isErrorPresented: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let movie = content.movie {
                MovieContentView(navigationPath: $navigationPath, movie: movie)
            } else {
                Group {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.red)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Error", isPresented: $isErrorPresented) {
            Button("Retry", role: .cancel) {
                Task {
                    await content.start(requestManager: requestManager)
                }
            }
        }
        .onChange(of: content.error) { error in
            isErrorPresented = error != nil
        }
        .task {
            await content.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(movieId: Movie.ID, navigationPath: Binding<NavigationPath>?) {
        self._content = StateObject(wrappedValue: Content(movieId: movieId))
        self._navigationPath = navigationPath ?? .constant(NavigationPath())
    }

    init(movie: Movie, navigationPath: Binding<NavigationPath>?) {
        self._content = StateObject(wrappedValue: Content(movie: movie))
        self._navigationPath = navigationPath ?? .constant(NavigationPath())
    }
}

private struct MovieContentView: View {

    @State private var contentOffset: CGFloat = 0
    @State private var contentInset: CGFloat = 0
    @State private var isImageLoaded: Bool = false
    @State private var isVideoPresented: MovieVideo? = nil

    private let cardOverlap: CGFloat = 24

    // MARK: Internal properties

    @Binding var navigationPath: NavigationPath

    let movie: Movie

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                PosterView(
                    isImageLoaded: $isImageLoaded,
                    imageHeight: $contentInset,
                    contentOffset: contentOffset,
                    movieMedia: movie.details.media
                )

                ObservableScrollView(scrollOffset: $contentOffset, showsIndicators: false) { scrollViewProxy in
                    VStack {
                        Spacer()
                            .frame(height: isImageLoaded
                                   ? max(0, contentInset - geometry.safeAreaInsets.top - cardOverlap)
                                   : geometry.size.height
                            )
                            .animation(.easeIn(duration: 0.4), value: isImageLoaded)

                        MovieCardView(movie: movie)
                    }
                }
            }
        }
        .safeAreaInset(edge: .top) {
            HeaderView(
                navigationPath: $navigationPath,
                isVideoPresented: $isVideoPresented,
                contentOffset: contentOffset,
                contentInset: contentInset,
                movieDetails: movie.details
            )
        }
        .overlay {
            Rectangle()
                .foregroundColor(.clear)
                .background(.thickMaterial)
                .ignoresSafeArea()
                .opacity(isImageLoaded ? 0 : 1)
                .animation(.easeIn(duration: 0.4), value: isImageLoaded)
        }
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
    }
}

private struct PosterView: View {

    @Binding var isImageLoaded: Bool
    @Binding var imageHeight: CGFloat

    let contentOffset: CGFloat
    let movieMedia: MovieMedia

    var body: some View {
        GeometryReader { mainGeometry in
            AsyncImage(
                url: movieMedia.posterUrl,
                content: { image in
                    image
                        .resizable()
                        .background(GeometryReader { imageGeometry in Color.clear.onAppear {
                            let imageRatio = imageGeometry.size.width / imageGeometry.size.height
                            imageHeight = mainGeometry.size.width / imageRatio
                            isImageLoaded = true
                        }})
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: { Color.clear }
            )
            .frame(
                width: UIScreen.main.bounds.width,
                height: max(0, isImageLoaded ? imageHeight - contentOffset : mainGeometry.size.height)
            )
            .clipped()
            .ignoresSafeArea(.all, edges: .top)
        }
    }
}

private struct HeaderView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var headerHeight: CGFloat = 0

    @Binding var navigationPath: NavigationPath
    @Binding var isVideoPresented: MovieVideo?

    let contentOffset: CGFloat
    let contentInset: CGFloat

    let movieDetails: MovieDetails

    private var shouldShowHeader: Bool {
        return contentOffset - contentInset + headerHeight > 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .center) {
                WatermarkView {
                    if !navigationPath.isEmpty {
                        Button(action: { navigationPath.removeLast() }) {
                            Image(systemName: "chevron.left")
                        }
                    } else {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "chevron.down")
                        }
                    }
                }

                if shouldShowHeader {
                    Text(movieDetails.title)
                        .lineLimit(2)
                        .font(.headline)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                }


                WatermarkView {
                    IconWatchlistButton(watchlistItem: .movie(id: movieDetails.id))

                    if !movieDetails.media.videos.isEmpty {
                        Menu {
                            ForEach(movieDetails.media.videos) { video in
                                Button(action: { isVideoPresented = video }) {
                                    switch video.type {
                                    case .trailer:
                                        Label("Trailer", systemImage: "play")
                                    case .teaser:
                                        Label("Teaser", systemImage: "play")
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "play.fill")
                        }

                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 20)
        .background(
            GeometryReader { geometry in
                Rectangle()
                    .fill(.background.opacity(0.2))
                    .background(.regularMaterial)
                    .opacity(shouldShowHeader ? 1 : 0)
                    .onAppear {
                        headerHeight = geometry.size.height
                    }
            }
        )
        .transition(.opacity)
        .animation(.easeOut(duration: 0.2), value: shouldShowHeader)
    }
}

#if DEBUG
struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
//        NavigationView {
            MovieView(movieId: 954, navigationPath: .constant(NavigationPath()))
                .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
                .environment(\.requestManager, MockRequestManager())
//        }
    }
}
#endif
