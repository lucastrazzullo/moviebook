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

    let movie: Movie

    // MARK: Object life cycle

    public init(movie: Movie) {
        self.movie = movie
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(Movie.ID.self, forKey: .id)
        let details = try TMDBMovieDetailsResponse(from: decoder).movieDetails
        let genres = try container.decode([TMDBMovieGenreResponse].self, forKey: .genres).map(\.genre)
        let keywords = try container.decode(TMDBMovieKeywordsResponse.self, forKey: .keywords).keywords.map(\.keyword)
        let production = try TMDBMovieProductionResponse(from: decoder).production
        let watch = WatchProviders(collections: [:])
        let collection = try container.decodeIfPresent(TMDBMovieCollectionResponse.self, forKey: .collection)?.collection
        let cast = try container.decode(TMDBMovieCastResponse.self, forKey: .credits).cast

        self.movie = Movie(id: id,
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

        try container.encode(movie.id, forKey: .id)
        try TMDBMovieDetailsResponse(movieDetails: movie.details).encode(to: encoder)
        try container.encode(movie.genres.map(TMDBMovieGenreResponse.init(genre:)), forKey: .genres)
        try container.encode(TMDBMovieKeywordsResponse(keywords: movie.keywords.map(TMDBMovieKeywordResponse.init(keyword:))), forKey: .keywords)
        try TMDBMovieProductionResponse(production: movie.production).encode(to: encoder)
        try container.encode(TMDBMovieCastResponse(cast: movie.cast), forKey: .credits)

        if let collection = movie.collection {
            try container.encode(TMDBMovieCollectionResponse(collection: collection), forKey: .collection)
        }
    }
}
