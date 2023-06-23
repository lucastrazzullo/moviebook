//
//  TMDBMovieGenreResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieGenreResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
    }

    let result: MovieGenre

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(MovieGenre.ID.self, forKey: .id)
        let name = try values.decode(String.self, forKey: .name)

        self.result = MovieGenre(id: id, name: name)
    }
}
