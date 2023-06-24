//
//  TMDBWatchProviderResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBWatchProviderResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case name = "provider_name"
        case logoPath = "logo_path"
    }

    let result: WatchProvider

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self, forKey: .name)
        let logoPath = try container.decode(String.self, forKey: .logoPath)
        let iconUrl = try TheMovieDbImageRequestFactory.makeURL(format: .logo(path: logoPath, size: .preview))

        self.result = WatchProvider(name: name, iconUrl: iconUrl)
    }
}
