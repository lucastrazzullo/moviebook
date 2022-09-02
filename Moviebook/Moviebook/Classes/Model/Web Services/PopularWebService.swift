//
//  PopularWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct PopularWebService {

    func fetch() async throws -> [MoviePreview] {
        let url = try TheMovieDbRequestFactory.makeURL(path: "movie/popular")
        let (data, _) = try await URLSession.shared.data(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithResults<MoviePreview>.self, from: data)

        return parsedResponse.results
    }
}
