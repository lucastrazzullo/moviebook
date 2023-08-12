//
//  ExploreFiltersViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/08/2023.
//

import Foundation
import MoviebookCommon

@MainActor final class ExploreFiltersViewModel: ObservableObject {

    @Published var selectedYear: Int?
    @Published var selectedGenres: Set<MovieGenre>

    @Published private(set) var genres: [MovieGenre] = []
    @Published private(set) var genresError: WebServiceError?

    let years: [Int]

    init(selectedGenres: Set<MovieGenre>) {
        self.years = Array(1930...Calendar.current.component(.year, from: .now))
        self.selectedGenres = selectedGenres
    }

    func start(requestLoader: RequestLoader) {
        Task {
            do {
                genresError = nil
                let webService = WebService.movieWebService(requestLoader: requestLoader)
                genres = try await webService.fetchMovieGenres()
            } catch let requestError {
                genresError = .failedToLoad(error: requestError, retry: { [weak self, weak requestLoader] in
                    guard let self, let requestLoader else { return }
                    self.start(requestLoader: requestLoader)
                })
            }
        }
    }
}
