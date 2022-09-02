//
//  Response.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

// MARK: - Response with results

struct ResponseWithResults<ItemType: Decodable>: Decodable {
    let results: [ItemType]
}

// MARK: - Entities Decoding Extensions

extension MoviePreview: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MoviePreview.ID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
    }
}
