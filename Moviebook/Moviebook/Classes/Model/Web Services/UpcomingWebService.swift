//
//  UpcomingWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct UpcomingWebService {

    func fetch() async throws -> [MoviePreview] {
        let url = try TheMovieDbRequestFactory.makeURL(path: "movie/upcoming")
        let (data, _) = try await URLSession.shared.data(from: url)
        let parsedResponse = try JSONDecoder().decode(TheMovieDbResponseWithResults<MoviePreview>.self, from: data)
        return parsedResponse.results
    }
}
