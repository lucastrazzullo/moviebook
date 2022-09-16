//
//  Request.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

enum TheMovieDbDataRequestFactory {

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
        let language = Locale.current.identifier

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

enum TheMovieDbImageRequestFactory {

    enum Error: Swift.Error {
        case cannotCreateURL
    }

    enum PosterSize: String {
        case thumb = "w185"
        case original = "original"
    }

    enum BackdropSize: String {
        case thumb = "w780"
        case original = "original"
    }

    enum Format {
        case poster(size: PosterSize)
        case backdrop(size: BackdropSize)

        var size: String {
            switch self {
            case .poster(let size):
                return size.rawValue
            case .backdrop(let size):
                return size.rawValue
            }
        }
    }

    static func makeURL(path: String, format: Format) throws -> URL {
        var components = defaultURLComponents()
        components.path = "/t/p/\(format.size)\(path)"

        guard let url = components.url else {
            throw Error.cannotCreateURL
        }

        return url
    }

    private static func defaultURLComponents() -> URLComponents {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "image.tmdb.org"
        return components
    }
}
