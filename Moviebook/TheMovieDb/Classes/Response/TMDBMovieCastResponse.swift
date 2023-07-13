//
//  TMDBMovieCastResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 14/07/2023.
//

import Foundation
import MoviebookCommon

public struct TMDBMovieCastResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case cast = "cast"
    }

    let result: [ArtistDetails]

    init(result: [ArtistDetails]) {
        self.result = result
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.result = try container.decode([TMDBSafeItemResponse<TMDBArtistDetailsResponse>].self, forKey: .cast).compactMap(\.value).map(\.result)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(result.map(TMDBArtistDetailsResponse.init(result:)), forKey: .cast)
    }
}
