//
//  SearchWebService.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 11/06/2023.
//

import Foundation

public protocol SearchWebService {

    func fetchMovies(with keyword: String, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?)
    func fetchArtists(with keyword: String, page: Int?) async throws -> (results: [ArtistDetails], nextPage: Int?)

    init(requestManager: RequestManager)
}
