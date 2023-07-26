//
//  TMDBMovieProductionResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieProductionResponse: Codable {

    struct Company: Codable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case production = "production_companies"
    }

    let production: MovieProduction

    // MARK: Object life cycle

    init(production: MovieProduction) {
        self.production = production
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let companies = try values.decode([Company].self, forKey: .production).map(\.name)

        self.production = MovieProduction(companies: companies)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(production.companies, forKey: .production)
    }
}
