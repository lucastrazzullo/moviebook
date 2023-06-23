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
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "person/\(identifier)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits")
        ])
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBArtistResponse.self, from: data).result
    }
}
