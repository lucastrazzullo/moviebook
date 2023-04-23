//
//  ArtistWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import Foundation

struct ArtistWebService {

    enum URLFactory {

        static func makeArtistUrl(artistIdentifier: Artist.ID) throws -> URL {
            return try TheMovieDbDataRequestFactory.makeURL(path: "person/\(artistIdentifier)", queryItems: [
                URLQueryItem(name: "append_to_response", value: "credits")
            ])
        }
    }

    enum Parser {

        static func parseArtist(data: Data) throws -> Artist {
            return try JSONDecoder().decode(Artist.self, from: data)
        }
    }

    let requestManager: RequestManager

    func fetchArtist(with identifier: Artist.ID) async throws -> Artist {
        let url = try URLFactory.makeArtistUrl(artistIdentifier: identifier)
        let data = try await requestManager.request(from: url)
        let artist = try Parser.parseArtist(data: data)

        return artist
    }
}
