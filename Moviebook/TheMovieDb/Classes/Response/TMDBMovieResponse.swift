//
//  TMDBMovieResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

public struct TMDBMovieResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case genres = "genres"
        case keywords = "keywords"
        case collection = "belongs_to_collection"
        case credits = "credits"
    }

    let result: Movie

    // MARK: Object life cycle

    public init(result: Movie) {
        self.result = result
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(Movie.ID.self, forKey: .id)
        let details = try TMDBMovieDetailsResponse(from: decoder).result
        let genres = try container.decode([TMDBMovieGenreResponse].self, forKey: .genres).map(\.result)
        let keywords = try container.decode(TMDBMovieKeywordsResponse.self, forKey: .keywords).keywords.map(\.result)
        let production = try TMDBMovieProductionResponse(from: decoder).result
        let watch = WatchProviders(collections: [:])
        let collection = try container.decodeIfPresent(TMDBMovieCollectionResponse.self, forKey: .collection)?.result
        let cast = try container.decode(TMDBMovieCastResponse.self, forKey: .credits).result

        self.result = Movie(id: id,
                            details: details,
                            genres: genres,
                            keywords: keywords,
                            cast: cast,
                            production: production,
                            watch: watch,
                            collection: collection)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(result.id, forKey: .id)
        try TMDBMovieDetailsResponse(result: result.details).encode(to: encoder)
        try container.encode(result.genres.map(TMDBMovieGenreResponse.init(result:)), forKey: .genres)
        try container.encode(TMDBMovieKeywordsResponse(keywords: result.keywords.map(TMDBMovieKeywordResponse.init(result:))), forKey: .keywords)
        try TMDBMovieProductionResponse(result: result.production).encode(to: encoder)
        try container.encode(TMDBMovieCastResponse(result: result.cast), forKey: .credits)

        if let collection = result.collection {
            try container.encode(TMDBMovieCollectionResponse(result: collection), forKey: .collection)
        }
    }
}
