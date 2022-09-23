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

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
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
        .task {
            await content.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(movieId: Movie.ID) {
        self._content = StateObject(wrappedValue: Content(movieId: movieId))
    }
}

private struct MovieContentView: View {

    @State private var contentOffset: CGFloat = 0
    @State private var contentInset: CGFloat = 480

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
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: max(0, geometry.frame(in: .global).minY + contentInset - contentOffset))
                            .background(GeometryReader { proxy in Color.clear.onAppear {
                                contentInset = proxy.size.height
                            }})
                    },
                    placeholder: { Color.clear }
                )
                .ignoresSafeArea(.all, edges: .top)
            }
            .frame(height: max(0, contentOffset))

            ObservableScrollView(scrollOffset: $contentOffset, showsIndicators: false) { scrollViewProxy in
                VStack {
                    Spacer().frame(height: contentInset - 24)

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
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .navigationBarHidden(isNavigationBarHidden)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(movie.details.title)
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
        return try? TheMovieDbImageRequestFactory.makeURL(path: path, format: .poster(size: .original))
    }
}

struct MovieView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieView(movieId: 954)
        }
    }
}
