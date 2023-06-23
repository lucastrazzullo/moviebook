//
//  TMDBMovieVideoResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieVideoResponse: Decodable {

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

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let official = try values.decode(Bool.self, forKey: .official)
        guard official else {
            throw DecodingError.nonOfficialTrailer
        }

        let id = try values.decode(String.self, forKey: .id)
        let name = try values.decode(String.self, forKey: .name)

        let typeString = try values.decode(String.self, forKey: .type)
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

        let key = try values.decode(String.self, forKey: .key)
        let site = try values.decode(String.self, forKey: .site)
        let source: MovieVideo.Source
        switch site {
        case "YouTube":
            source = .youtube(id: key)
        default:
            throw DecodingError.siteNotSupported(site)
        }

        self.result = MovieVideo(id: id, name: name, type: type, source: source)
    }
}
