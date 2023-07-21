//
//  TMDBMovieDetailsResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieDetailsResponse: Codable {

    enum Error: Swift.Error {
        case invalidDate
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case overview = "overview"
        case budget = "budget"
        case revenue = "revenue"
        case releaseDate = "release_date"
        case releaseDates = "release_dates"
        case runtime = "runtime"
        case rating = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    let movieDetails: MovieDetails

    // MARK: Object life cycle

    init(movieDetails: MovieDetails) {
        self.movieDetails = movieDetails
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(MovieDetails.ID.self, forKey: .id)
        let title = try values.decode(String.self, forKey: .title)
        let overview = try values.decodeIfPresent(String.self, forKey: .overview)
        let rating = Rating(value: try values.decode(Float.self, forKey: .rating), quota: 10.0)
        let media = try TMDBMovieMediaResponse(from: decoder).media

        var localisedReleases: [String: Date] = [:]
        if let releaseList = try values.decodeIfPresent(TMDBResponseWithListResults<TMDBMovieLocalisedRelease>.self, forKey: .releaseDates)?.results {
            localisedReleases = Dictionary(uniqueKeysWithValues: releaseList.compactMap { localisedRelease in
                return (localisedRelease.region, localisedRelease.theatricalReleaseDate)
            })
        }

        let releaseDateString = try values.decode(String.self, forKey: .releaseDate)
        guard let releaseDate = TheMovieDbFactory.dateFormatter.date(from: releaseDateString) else {
            throw Error.invalidDate
        }

        let minutes = try values.decodeIfPresent(Int.self, forKey: .runtime)
        var runtime: TimeInterval?
        if let minutes = minutes {
            runtime = TimeInterval(minutes*60)
        }

        let currency = Locale.current.currency?.identifier ?? "EUR"
        var budget: MoneyValue?
        if let budgetValue = try values.decodeIfPresent(Int.self, forKey: .budget) {
            budget = MoneyValue(value: budgetValue, currencyCode: currency)
        }

        var revenue: MoneyValue?
        if let revenueValue = try values.decodeIfPresent(Int.self, forKey: .revenue) {
            revenue = MoneyValue(value: revenueValue, currencyCode: currency)
        }

        self.movieDetails = MovieDetails(id: id,
                                   title: title,
                                   release: releaseDate,
                                   localisedReleases: localisedReleases,
                                   runtime: runtime,
                                   overview: overview,
                                   budget: budget,
                                   revenue: revenue,
                                   rating: rating,
                                   media: media)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(movieDetails.id, forKey: .id)
        try container.encode(movieDetails.title, forKey: .title)
        try container.encode(movieDetails.rating.value, forKey: .rating)
        try container.encode(TheMovieDbFactory.dateFormatter.string(from: movieDetails.release), forKey: .releaseDate)

        var releaseDates: [TMDBMovieLocalisedRelease] = []
        for releaseRegion in movieDetails.localisedReleases.keys {
            if let releaseDate = movieDetails.localisedReleases[releaseRegion] {
                releaseDates.append(TMDBMovieLocalisedRelease(region: releaseRegion, theatricalReleaseDate: releaseDate))
            }
        }
        try container.encode(TMDBResponseWithListResults(results: releaseDates), forKey: .releaseDates)

        try TMDBMovieMediaResponse(media: movieDetails.media).encode(to: encoder)

        try container.encodeIfPresent(movieDetails.overview, forKey: .overview)
        try container.encodeIfPresent(movieDetails.budget?.value, forKey: .budget)
        try container.encodeIfPresent(movieDetails.revenue?.value, forKey: .revenue)

        if let runtime = movieDetails.runtime {
            try container.encode(runtime/60, forKey: .runtime)
        }
    }
}
