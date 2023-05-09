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

    static func makeURL(path: String, page: Int? = nil, queryItems: [URLQueryItem] = []) throws -> URL {
        let version = 3

        var queryItems = queryItems
        if let region = Configuration.region {
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
        let language = Configuration.language

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
        case preview = "w780"
        case original = "original"
    }

    enum BackdropSize: String {
        case preview = "w1280"
        case original = "original"
    }

    enum AvatarSize: String {
        case preview = "h632"
        case original = "original"
    }

    enum LogoSize: String {
        case preview = "w154"
    }

    enum Format {
        case poster(path: String, size: PosterSize)
        case backdrop(path: String, size: BackdropSize)
        case avatar(path: String, size: AvatarSize)
        case logo(path: String, size: LogoSize)

        var size: String {
            switch self {
            case .poster(_, let size):
                return size.rawValue
            case .backdrop(_, let size):
                return size.rawValue
            case .avatar(_, let size):
                return size.rawValue
            case .logo(_, let size):
                return size.rawValue
            }
        }

        var path: String {
            switch self {
            case .poster(let path, _):
                return path
            case .backdrop(let path, _):
                return path
            case .avatar(let path, _):
                return path
            case .logo(let path, _):
                return path
            }
        }
    }

    static func makeURL(format: Format) throws -> URL {
        var components = defaultURLComponents()
        components.path = "/t/p/\(format.size)\(format.path)"

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
