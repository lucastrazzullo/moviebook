//
//  Favourites+Mock.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/09/2023.
//

#if DEBUG

import Foundation
import MoviebookCommon
import MoviebookTestSupport

extension MockFavouritesProvider {

    static let shared: MockFavouritesProvider = MockFavouritesProvider()
}
#endif
