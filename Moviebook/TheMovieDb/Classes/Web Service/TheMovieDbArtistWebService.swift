//
//  TheMovieDbArtistWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import Foundation
import MoviebookCommon

public struct TheMovieDbArtistWebService: ArtistWebService {

    private let requestManager: RequestManager

    public init(requestManager: RequestManager) {
        self.requestManager = requestManager
    }

    public func fetchArtist(with identifier: Artist.ID) async throws -> Artist {
        let url = try TheMovieDbUrlFactory.artist(identifier: identifier).makeUrl()
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBArtistResponse.self, from: data).artist
    }

    public func fetchPopular(page: Int?) async throws -> (results: [ArtistDetails], nextPage: Int?) {
        let url = try TheMovieDbUrlFactory.popularArtists(page: page).makeUrl()
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBArtistDetailsResponse>.self, from: data)
        return (results: response.results.map(\.artistDetails), nextPage: response.nextPage)
    }
}
