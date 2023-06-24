//
//  TMDBMovieVideoResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieVideoResponse: Codable {

    enum DecodingError: Error {
        case siteNotSupported(_ site: String)
        case typeNotSupported(_ type: String)
        case nonOfficialTrailer
    }

    enum CodingKeys: CodingKey {
        case id
        case name
        case key
        case site
        case type
        case official
    }

    let result: MovieVideo

    // MARK: Object life cycle

    init(result: MovieVideo) {
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let official = try container.decode(Bool.self, forKey: .official)
        guard official else {
            throw DecodingError.nonOfficialTrailer
        }

        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)

        let typeString = try container.decode(String.self, forKey: .type)
        let type: MovieVideo.MediaType
        switch typeString {
        case "Trailer":
            type = .trailer
        case "Teaser":
            type = .teaser
        case "Behind the Scenes":
            type = .behindTheScenes
        default:
            throw DecodingError.typeNotSupported(typeString)
        }

        let key = try container.decode(String.self, forKey: .key)
        let site = try container.decode(String.self, forKey: .site)
        let source: MovieVideo.Source
        switch site {
        case "YouTube":
            source = .youtube(id: key)
        default:
            throw DecodingError.siteNotSupported(site)
        }

        self.result = MovieVideo(id: id, name: name, type: type, source: source)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(result.id, forKey: .id)
        try container.encode(result.name, forKey: .name)

        let type: String
        switch result.type {
        case .trailer:
            type = "Trailer"
        case .teaser:
            type = "Teaser"
        case .behindTheScenes:
            type = "Behind the Scenes"
        }

        let key: String
        let site: String
        switch result.source {
        case .youtube(let id):
            key = id
            site = "YouTube"
        }

        try container.encode(type, forKey: .type)
        try container.encode(key, forKey: .key)
        try container.encode(site, forKey: .site)
    }
}
