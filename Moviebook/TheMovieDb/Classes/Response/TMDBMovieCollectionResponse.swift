//
//  TMDBMovieCollectionResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieCollectionResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case list = "parts"
    }

    let collection: MovieCollection

    // MARK: Object life cycle

    init(collection: MovieCollection) {
        self.collection = collection
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(MovieCollection.ID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let list = try container.decodeIfPresent([TMDBSafeItemResponse<TMDBMovieDetailsResponse>].self, forKey: .list)?
            .compactMap(\.value)
            .map(\.movieDetails) ?? []

        self.collection = MovieCollection(id: id, name: name, list: list)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(collection.id, forKey: .id)
        try container.encode(collection.name, forKey: .name)
        try container.encode(collection.list.map(TMDBMovieDetailsResponse.init(movieDetails:)), forKey: .list)
    }
}
