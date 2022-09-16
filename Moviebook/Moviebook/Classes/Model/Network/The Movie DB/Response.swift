//
//  Response.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

// MARK: - Response with results

struct TheMovieDbResponseWithResults<ItemType: Decodable>: Decodable {
    let results: [ItemType]
}

// MARK: - Entities Decoding Extensions

extension MovieDetails: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieDetails.ID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)

        if let posterPath = try values.decodeIfPresent(String.self, forKey: .posterPath) {
            posterURL = try? TheMovieDbImageRequestFactory.makeURL(path: posterPath, format: .poster(size: .thumb))
        } else {
            posterURL = nil
        }
        if let backdropPath = try values.decodeIfPresent(String.self, forKey: .backdropPath) {
            backdropURL = try? TheMovieDbImageRequestFactory.makeURL(path: backdropPath, format: .backdrop(size: .thumb))
        } else {
            backdropURL = nil
        }
    }
}
