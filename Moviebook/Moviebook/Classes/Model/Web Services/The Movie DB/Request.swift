//
//  Request.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

enum TheMovieDbRequestFactory {

    enum Error: Swift.Error {
        case cannotCreateURL
    }

    static func makeURL(path: String, region: String? = Locale.current.regionCode, page: Int? = nil) throws -> URL {
        let version = 3

        var queryItems = [URLQueryItem]()
        if let region = region {
            queryItems.append(URLQueryItem(name: "region", value: region))
        }
        if let page = page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }

        var components = defaultURLComponents()
        components.path = "/\(version)/\(path)"
        components.queryItems?.append(contentsOf: queryItems)

        guard let url = components.url else {
            throw Error.cannotCreateURL
        }

        return url
    }

    private static func defaultURLComponents() -> URLComponents {
        let language = NSLocalizedString("API.LANGUAGE", comment: "")

        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.queryItems = [
            URLQueryItem(name: "api_key", value: "9e718d9095bcf7e3e6dbe26672500060"),
            URLQueryItem(name: "language", value: language)
        ]
        return components
    }
}
