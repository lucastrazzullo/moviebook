//
//  Watchlist+Mock.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 10/07/2023.
//

#if DEBUG

import Foundation
import MoviebookCommon
import MoviebookTestSupport

extension MockWatchlistProvider {

    static let shared: MockWatchlistProvider = MockWatchlistProvider()
}
#endif
