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

    @State private var isNavigationBarHidden: Bool = true

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let movie = content.movie {
                MovieContentView(isNavigationBarHidden: $isNavigationBarHidden, movie: movie)
            } else {
                ProgressView()
            }

            if isNavigationBarHidden {
                MovieHeaderView()
            }
        }
        .background(.black)
        .task {
            await content.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(movieId: Movie.ID) {
        self._content = StateObject(wrappedValue: Content(movieId: movieId))
    }
}

private struct MovieHeaderView: View {

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.left")
                .font(.subheadline.bold())
                .padding()
                .background(Circle().fill(.ultraThickMaterial))
        }
        .padding(.leading)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

private struct MovieContentView: View {

    @State private var contentOffset: CGFloat = 0
    @State private var contentInset: CGFloat = 0
    @State private var isImageLoaded: Bool = false

    @Binding var isNavigationBarHidden: Bool

    let movie: Movie

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                AsyncImage(
                    url: imageUrl,
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
                    height: max(0, isImageLoaded ? geometry.frame(in: .global).minY + contentInset - contentOffset : UIScreen.main.bounds.height)
                )
                .animation(.easeIn(duration: 0.6), value: isImageLoaded)
                .ignoresSafeArea(.all, edges: .top)
            }
            .frame(height: max(0, contentOffset))

            ObservableScrollView(scrollOffset: $contentOffset, showsIndicators: false) { scrollViewProxy in
                VStack {
                    Spacer()
                        .frame(height: isImageLoaded ? contentInset - 24 : UIScreen.main.bounds.height)

                    VStack(alignment: .leading, spacing: 24) {
                        Text(movie.details.title)
                            .font(.title2)

                        Text(movie.overview)
                            .font(.body)
                            .lineSpacing(12)

                        Spacer()
                            .frame(height: 600)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.thickMaterial)
                    .cornerRadius(12)
                }
                .animation(.easeOut(duration: 0.6), value: isImageLoaded)
                .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .overlay {
            Rectangle()
                .background(.thickMaterial)
                .ignoresSafeArea()
                .opacity(isImageLoaded ? 0 : 1)
                .animation(.easeIn(duration: 0.6), value: isImageLoaded)
        }
        .navigationBarHidden(isNavigationBarHidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(movie.details.title)
        .toolbar(.hidden, for: .tabBar)
        .onChange(of: contentOffset) { offset in
            if offset < contentInset - 80 {
                isNavigationBarHidden = true
            } else {
                isNavigationBarHidden = false
            }
        }
        .animation(.default, value: isNavigationBarHidden)
    }

    var imageUrl: URL? {
        guard let path = movie.details.posterPath else {
            return nil
        }
        return try? TheMovieDbImageRequestFactory.makeURL(path: path, format: .poster(size: .large))
    }
}

struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 954)
        }
    }
}
