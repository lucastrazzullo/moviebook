//
//  DiscoverGenresViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/07/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class DiscoverGenresViewModel: ObservableObject {

    @Published var selectedGenres: Set<MovieGenre> = []

    @Published private(set) var genres: [MovieGenre] = []
    @Published private(set) var error: WebServiceError?

    func start(requestManager: RequestManager) {
        Task {
            do {
                let webService = WebService.movieWebService(requestManager: requestManager)
                self.genres = try await webService.fetchMovieGenres()
                self.error = nil
            } catch {
                self.error = .failedToLoad(id: UUID.init(), retry: { [weak self, weak requestManager] in
                    guard let self, let requestManager else { return }
                    self.start(requestManager: requestManager)
                })
            }
        }
    }
}
