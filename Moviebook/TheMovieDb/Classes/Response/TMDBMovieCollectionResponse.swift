//
//  TMDBMovieCollectionResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieCollectionResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case list = "parts"
    }

    let result: MovieCollection

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(MovieCollection.ID.self, forKey: .id)
        let name = try values.decode(String.self, forKey: .name)
        let list = try values.decodeIfPresent([TMDBSafeItemResponse<TMDBMovieDetailsResponse>].self, forKey: .list)?
            .compactMap(\.value)
            .map(\.result) ?? []

        self.result = MovieCollection(id: id, name: name, list: list)
    }
}
