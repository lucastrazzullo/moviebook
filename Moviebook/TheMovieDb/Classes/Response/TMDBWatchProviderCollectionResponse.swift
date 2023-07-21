//
//  TMDBWatchProviderCollectionResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBWatchProviderCollectionResponse: Decodable {

    enum CodingKeys: CodingKey {
        case buy
        case rent
        case flatrate
    }

    let providers: WatchProviderCollection

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let free = try container.decodeIfPresent([TMDBWatchProviderResponse].self, forKey: .flatrate)?.map(\.provider) ?? []
        let rent = try container.decodeIfPresent([TMDBWatchProviderResponse].self, forKey: .rent)?.map(\.provider) ?? []
        let buy = try container.decodeIfPresent([TMDBWatchProviderResponse].self, forKey: .buy)?.map(\.provider) ?? []

        self.providers = WatchProviderCollection(free: free, rent: rent, buy: buy)
    }
}
