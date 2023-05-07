//
//  MovieViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/04/2023.
//

import Foundation

@MainActor final class MovieViewModel: ObservableObject {

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