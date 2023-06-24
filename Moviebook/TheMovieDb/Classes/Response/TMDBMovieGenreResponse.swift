//
//  TMDBMovieGenreResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieGenreResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
    }

    let result: MovieGenre

    // MARK: Object life cycle

    init(result: MovieGenre) {
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(MovieGenre.ID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)

        self.result = MovieGenre(id: id, name: name)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(result.id, forKey: .id)
        try container.encode(result.name, forKey: .name)
    }
}