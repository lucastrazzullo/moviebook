//
//  TMDBResponseWithDictionaryResults.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBResponseWithDictionaryResults<ItemType: Decodable>: Decodable {

    enum CodingKeys: CodingKey {
        case results
    }

    let results: [String: ItemType]

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([String: ItemType].self, forKey: CodingKeys.results)
    }
}
