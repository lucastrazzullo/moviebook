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
        case collection = "belongs_to_collection"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieDetails.ID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        collection = try values.decodeIfPresent(MovieCollection.self, forKey: .collection)
    }
}

extension MovieCollection: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieCollection.ID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
    }
}
