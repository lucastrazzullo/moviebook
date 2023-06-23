//
//  TheMovieDbArtistWebService.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBArtistResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case credits = "credits"
    }

    enum CreditsCodingKeys: String, CodingKey {
        case cast
    }

    let result: Artist

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(Movie.ID.self, forKey: .id)
        let details = try TMDBArtistDetailsResponse(from: decoder).result

        let creditsContainer = try values.nestedContainer(keyedBy: CreditsCodingKeys.self, forKey: .credits)
        let filmography = try creditsContainer.decodeIfPresent([TMDBSafeItemResponse<TMDBMovieDetailsResponse>].self, forKey: .cast)?
            .compactMap(\.value)
            .map(\.result) ?? []

        self.result = Artist(id: id, details: details, filmography: filmography)
    }
}
