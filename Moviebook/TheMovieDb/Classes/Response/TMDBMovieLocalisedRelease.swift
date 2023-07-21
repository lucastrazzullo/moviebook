//
//  TMDBMovieLocalisedRelease.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 19/07/2023.
//

import Foundation

struct TMDBMovieLocalisedRelease: Codable {

    enum CodingError: Error {
        case missingTheatricalRelease
    }

    enum CodingKeys: String, CodingKey {
        case region = "iso_3166_1"
        case releaseDates = "release_dates"
    }

    let region: String
    let theatricalReleaseDate: Date

    init(region: String, theatricalReleaseDate: Date) {
        self.region = region
        self.theatricalReleaseDate = theatricalReleaseDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        guard let theatricalReleaseDate = try container
            .decode([TMDBSafeItemResponse<TMDBMovieReleaseDate>].self, forKey: .releaseDates)
            .compactMap(\.value)
            .first(where: { $0.type == .theatrical || $0.type == .theatricalLimited })?.date else {
            throw CodingError.missingTheatricalRelease
        }

        self.region = try container.decode(String.self, forKey: .region)
        self.theatricalReleaseDate = theatricalReleaseDate
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.region, forKey: .region)
        try container.encode(TMDBMovieReleaseDate(date: theatricalReleaseDate, type: .theatrical), forKey: .releaseDates)
    }
}

struct TMDBMovieReleaseDate: Codable {

    enum CodingError: Error {
        case cannotParseDate
    }

    enum ReleaseDateType: Int, Codable {
        case premiere = 1
        case theatricalLimited
        case theatrical
        case digital
        case physical
        case tv
    }

    enum CodingKeys: String, CodingKey {
        case releaseDate = "release_date"
        case type = "type"
    }

    let date: Date
    let type: ReleaseDateType

    init(date: Date, type: ReleaseDateType) {
        self.date = date
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let dateString = try container.decode(String.self, forKey: .releaseDate)
        guard let date = TheMovieDbFactory.localisedDateFormatter.date(from: dateString) else {
            throw CodingError.cannotParseDate
        }

        self.date = date
        self.type = try container.decode(ReleaseDateType.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let dateString = TheMovieDbFactory.dateFormatter.string(from: date)

        try container.encode(dateString, forKey: .releaseDate)
        try container.encode(type.rawValue, forKey: .type)
    }
}
