//
//  TMDBResponseWithListResults.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBResponseWithListResults<ItemType: Decodable>: Decodable {

    let results: [ItemType]
    let nextPage: Int?

    enum CodingKeys: CodingKey {
        case results
        case page
        case total_pages
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([TMDBSafeItemResponse<ItemType>].self, forKey: CodingKeys.results).compactMap(\.value)

        if let page = try container.decodeIfPresent(Int.self, forKey: .page),
           let numberOfPages = try container.decodeIfPresent(Int.self, forKey: .total_pages),
            page < numberOfPages {
            self.nextPage = page + 1
        } else {
            self.nextPage = nil
        }
    }
}
