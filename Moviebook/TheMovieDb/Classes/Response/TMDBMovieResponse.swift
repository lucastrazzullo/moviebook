//
//  TMDBMovieResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case genres = "genres"
        case collection = "belongs_to_collection"
        case credits = "credits"
    }

    enum CreditsCodingKeys: String, CodingKey {
        case cast = "cast"
    }

    let result: Movie

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(Movie.ID.self, forKey: .id)
        let details = try TMDBMovieDetailsResponse(from: decoder).result
        let genres = try values.decode([TMDBMovieGenreResponse].self, forKey: .genres).map(\.result)
        let production = try TMDBMovieProductionResponse(from: decoder).result
        let watch = WatchProviders(collections: [:])
        let collection = try values.decodeIfPresent(TMDBMovieCollectionResponse.self, forKey: .collection)?.result

        let creditsContainer = try values.nestedContainer(keyedBy: CreditsCodingKeys.self, forKey: .credits)
        let cast = try creditsContainer.decode([TMDBSafeItemResponse<TMDBArtistDetailsResponse>].self, forKey: .cast).compactMap(\.value).map(\.result)

        self.result = Movie(id: id,
                            details: details,
                            genres: genres,
                            cast: cast,
                            production: production,
                            watch: watch,
                            collection: collection)
    }
}
