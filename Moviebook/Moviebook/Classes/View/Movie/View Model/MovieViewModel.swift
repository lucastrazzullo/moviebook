//
//  MovieViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/04/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class MovieViewModel: ObservableObject {

    // MARK: Instance Properties

    @Published var movie: Movie?
    @Published var error: WebServiceError?

    private let movieId: Movie.ID
    private var task: Task<Void, Never>?

    // MARK: Object life cycle

    init(movieId: Movie.ID) {
        self.movieId = movieId
    }

    deinit {
        self.task?.cancel()
    }

    // MARK: Instance methods

    func start(requestLoader: RequestLoader) {
        task = Task {
            do {
                let movie = try await WebService.movieWebService(requestLoader: requestLoader).fetchMovie(with: movieId)
                guard let task, !task.isCancelled else { return }
                setMovie(movie)
            } catch {
                self.error = .failedToLoad(id: .init(), retry: { [weak self, weak requestLoader] in
                    if let requestLoader {
                        self?.start(requestLoader: requestLoader)
                    }
                })
            }
        }
    }

    private func setMovie(_ movie: Movie) {
        self.movie = movie
        Spotlight.index(movie: movie)
    }
}
