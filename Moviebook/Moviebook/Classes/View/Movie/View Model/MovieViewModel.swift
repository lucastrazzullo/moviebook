//
//  MovieViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/04/2023.
//

import Foundation
import CoreSpotlight

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
        self.index(movie: movie)
    }

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        guard movie == nil else { return }
        loadMovie(requestManager: requestManager)
    }

    private func loadMovie(requestManager: RequestManager) {
        Task {
            do {
                let movie = try await MovieWebService(requestManager: requestManager).fetchMovie(with: movieId)
                self.movie = movie
                index(movie: movie)
            } catch {
                self.error = .failedToLoad(id: .init(), retry: { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.loadMovie(requestManager: requestManager)
                    }
                })
            }
        }
    }

    private func index(movie: Movie) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.displayName = movie.details.title

        let url = Deeplink.movie(identifier: movie.id).rawValue
        let searchableItem = CSSearchableItem(uniqueIdentifier: url.absoluteString, domainIdentifier: "movie", attributeSet: attributeSet)

        CSSearchableIndex.default().indexSearchableItems([searchableItem])
    }
}
