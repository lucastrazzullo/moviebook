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

    static func movieWebService(requestLoader: RequestLoader) -> MovieWebService {
        return TheMovieDbMovieWebService(requestLoader: requestLoader)
    }

    static func artistWebService(requestLoader: RequestLoader) -> ArtistWebService {
        return TheMovieDbArtistWebService(requestLoader: requestLoader)
    }

    static func searchWebService(requestLoader: RequestLoader) -> SearchWebService {
        return TheMovieDbSearchWebService(requestLoader: requestLoader)
    }
}
