//
//  Response.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

// MARK: - Response with results

enum TheMovieDbResponse {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct TMDBSafeItemResponse<Base: Decodable>: Decodable {
    public let value: Base?

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.singleValueContainer()
            self.value = try container.decode(Base.self)
        } catch {
            self.value = nil
        }
    }
}

struct TMDBResponseWithListResults<ItemType: Decodable>: Decodable {

    let results: [ItemType]

    enum CodingKeys: CodingKey {
        case results
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([TMDBSafeItemResponse<ItemType>].self, forKey: CodingKeys.results).compactMap(\.value)
    }
}

struct TheMovieDbResponseWithDictionaryResults<ItemType: Decodable>: Decodable {

    let results: [String: ItemType]

    enum CodingKeys: CodingKey {
        case results
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([String: ItemType].self, forKey: CodingKeys.results)
    }
}
