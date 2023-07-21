//
//  TMDBResponseWithListResults.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBResponseWithListResults<ItemType: Codable>: Codable {

    enum CodingKeys: CodingKey {
        case results
        case page
        case total_pages
    }

    let results: [ItemType]
    let nextPage: Int?

    init(results: [ItemType]) {
        self.results = results
        self.nextPage = nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([TMDBSafeItemResponse<ItemType>].self, forKey: CodingKeys.results).compactMap(\.value)

        if let page = try container.decodeIfPresent(Int.self, forKey: .page),
           let numberOfPages = try container.decodeIfPresent(Int.self, forKey: .total_pages),
            page < numberOfPages {
            self.nextPage = page + 1
        } else {
            self.nextPage = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(results, forKey: .results)
    }
}
