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
                MovieContentView(movie: movie, navigationPath: $navigationPath)
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

    init(movieId: Movie.ID, navigationPath: Binding<NavigationPath>) {
        self._content = StateObject(wrappedValue: Content(movieId: movieId))
        self._navigationPath = navigationPath
    }

    init(movie: Movie, navigationPath: Binding<NavigationPath>?) {
        self._content = StateObject(wrappedValue: Content(movie: movie))
        self._navigationPath = navigationPath ?? .constant(NavigationPath())
    }
}

private struct MovieContentView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var contentOffset: CGFloat = 0
    @State private var contentInset: CGFloat = 0
    @State private var isImageLoaded: Bool = false

    private let headerHeight: CGFloat = 100

    let movie: Movie

    @Binding var navigationPath: NavigationPath

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                AsyncImage(
                    url: movie.details.media.posterPreviewUrl,
                    content: { image in
                        image
                            .resizable()
                            .background(GeometryReader { proxy in Color.clear.onAppear {
                                let imageRatio = proxy.size.width / proxy.size.height
                                contentInset = UIScreen.main.bounds.width / imageRatio
                                isImageLoaded = true
                            }})
                            .aspectRatio(contentMode: .fill)
                    },
                    placeholder: { Color.clear }
                )
                .frame(
                    width: UIScreen.main.bounds.width,
                    height: max(headerHeight, isImageLoaded ? geometry.safeAreaInsets.top + contentInset - contentOffset : UIScreen.main.bounds.height)
                )
                .clipped()
                .ignoresSafeArea(.all, edges: .top)
            }
            .frame(height: max(0, contentOffset))

            ObservableScrollView(scrollOffset: $contentOffset, showsIndicators: false) { scrollViewProxy in
                VStack {
                    Spacer()
                        .frame(height: isImageLoaded ? contentInset - 24 : UIScreen.main.bounds.height)
                        .animation(.easeIn(duration: 0.4), value: isImageLoaded)

                    MovieCardView(movie: movie)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    HStack(alignment: .center) {
                        Group {
                            if !navigationPath.isEmpty {
                                Button(action: { navigationPath.removeLast() }) {
                                    Image(systemName: "chevron.left")
                                        .font(.subheadline.bold())
                                        .frame(width: 32, height: 24)
                                        .padding(4)
                                }
                            } else {
                                Button(action: dismiss.callAsFunction) {
                                    Image(systemName: "chevron.down")
                                        .font(.subheadline.bold())
                                        .frame(width: 32, height: 24)
                                        .padding(4)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 0)
                        .background(.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)

                        if shouldShowHeader(geometry: geometry) {
                            Text(movie.details.title)
                                .lineLimit(2)
                                .font(.headline)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .frame(maxWidth: .infinity)
                        } else {
                            Spacer()
                        }

                        Group {
                            IconWatchlistButton(watchlistItem: .movie(id: movie.id))
                                .font(.subheadline.bold())
                                .frame(width: 32, height: 24)
                                .padding(4)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 0)
                        .background(.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .frame(height: headerHeight + 2, alignment: .bottom)
                .background(
                    Rectangle()
                        .fill(.background.opacity(0.2))
                        .background(.regularMaterial)
                        .opacity(shouldShowHeader(geometry: geometry) ? 1 : 0)
                )
                .ignoresSafeArea(.all, edges: .top)
                .transition(.opacity)
                .animation(.easeOut(duration: 0.2), value: contentOffset)
            }
        }
        .overlay {
            Rectangle()
                .foregroundColor(.clear)
                .background(.thickMaterial)
                .ignoresSafeArea()
                .opacity(isImageLoaded ? 0 : 1)
                .animation(.easeIn(duration: 0.4), value: isImageLoaded)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(movie.details.title)
    }

    private func shouldShowHeader(geometry: GeometryProxy) -> Bool {
        contentOffset - contentInset - geometry.safeAreaInsets.top > -headerHeight
    }
}

#if DEBUG
struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 954, navigationPath: .constant(NavigationPath()))
                .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
        }
    }
}
#endif
