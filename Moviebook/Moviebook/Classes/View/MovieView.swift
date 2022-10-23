//
//  MovieView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/09/2022.
//

import SwiftUI

@MainActor private final class Content: ObservableObject {

    @Published var movie: Movie?

    private let movieId: Movie.ID

    // MARK: Object life cycle

    init(movieId: Movie.ID) {
        self.movieId = movieId
    }

    // MARK: Instance methods

    func start(requestManager: RequestManager) async {
        do {
            movie = try await MovieWebService(requestManager: requestManager).fetchMovie(with: movieId)
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

struct MovieView: View {

    @Environment(\.requestManager) var requestManager

    @StateObject private var content: Content

    @Binding private var navigationPath: NavigationPath

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
        .task {
            await content.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(movieId: Movie.ID, navigationPath: Binding<NavigationPath>) {
        self._content = StateObject(wrappedValue: Content(movieId: movieId))
        self._navigationPath = navigationPath
    }
}

private struct MovieContentView: View {

    @Environment(\.colorScheme) private var colorScheme

    @State private var contentOffset: CGFloat = 0
    @State private var contentInset: CGFloat = 0
    @State private var isImageLoaded: Bool = false

    private let headerHeight: CGFloat = 120

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
                    height: max(headerHeight, isImageLoaded ? geometry.frame(in: .global).minY + contentInset - contentOffset : UIScreen.main.bounds.height)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .ignoresSafeArea(.all, edges: .top)
            }
            .frame(height: max(0, contentOffset))

            ObservableScrollView(scrollOffset: $contentOffset, showsIndicators: false) { scrollViewProxy in
                VStack {
                    Spacer()
                        .frame(height: isImageLoaded ? contentInset : UIScreen.main.bounds.height)

                    MovieCardView(movie: movie)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    ZStack(alignment: .center) {
                        Group {
                            Button(action: { navigationPath.removeLast() }) {
                                Image(systemName: "chevron.left")
                                    .font(.subheadline.bold())
                                    .frame(width: 46, height: 46)
                                    .background(Circle().fill(.ultraThickMaterial))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Group {
                            WatchlistButton(watchlistItem: .movie(id: movie.id))
                                .font(.subheadline.bold())
                                .frame(width: 46, height: 46)
                                .background(Circle().fill(.ultraThickMaterial))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        if shouldShowHeader(geometry: geometry) {
                            Text(movie.details.title)
                                .font(.headline)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
        contentOffset - contentInset - geometry.frame(in: .global).minY > -headerHeight
    }
}

struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 954, navigationPath: .constant(NavigationPath()))
                .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
        }
    }
}
