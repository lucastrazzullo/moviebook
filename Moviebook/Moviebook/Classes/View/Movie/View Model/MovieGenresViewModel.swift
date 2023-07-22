//
//  MovieGenresViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/07/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class MovieGenresViewModel: ObservableObject {

    @Published var selectedGenres: Set<MovieGenre> = []

    @Published private(set) var genres: [MovieGenre] = []
    @Published private(set) var error: WebServiceError?

    func start(requestLoader: RequestLoader) {
        Task {
            do {
                let webService = WebService.movieWebService(requestLoader: requestLoader)
                self.genres = try await webService.fetchMovieGenres()
                self.error = nil
            } catch {
                self.error = .failedToLoad(id: UUID.init(), retry: { [weak self, weak requestLoader] in
                    guard let self, let requestLoader else { return }
                    self.start(requestLoader: requestLoader)
                })
            }
        }
    }
}
