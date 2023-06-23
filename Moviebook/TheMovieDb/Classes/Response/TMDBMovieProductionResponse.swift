//
//  TMDBMovieProductionResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieProductionResponse: Decodable {

    struct Company: Decodable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case production = "production_companies"
    }

    let result: MovieProduction

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let companies = try values.decode([Company].self, forKey: .production).map(\.name)

        self.result = MovieProduction(companies: companies)
    }
}
