//
//  WebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import TheMovieDb
import MoviebookCommon

enum WebService {

    static func movieWebService(requestManager: RequestManager) -> MovieWebService {
        return TheMovieDbMovieWebService(requestManager: requestManager)
    }

    static func artistWebService(requestManager: RequestManager) -> ArtistWebService {
        return TheMovieDbArtistWebService(requestManager: requestManager)
    }

    static func searchWebService(requestManager: RequestManager) -> SearchWebService {
        return TheMovieDbSearchWebService(requestManager: requestManager)
    }
}
