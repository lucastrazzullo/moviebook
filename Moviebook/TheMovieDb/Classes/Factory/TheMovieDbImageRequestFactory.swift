//
//  TheMovieDbImageRequestFactory.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation

public enum TheMovieDbImageRequestFactory {

    public enum Error: Swift.Error {
        case cannotCreateURL
    }

    public enum PosterSize: String {
        case thumbnail = "w185"
        case preview = "w780"
        case original = "original"
    }

    public enum BackdropSize: String {
        case preview = "w1280"
        case original = "original"
    }

    public enum AvatarSize: String {
        case preview = "h632"
        case original = "original"
    }

    public enum LogoSize: String {
        case preview = "w154"
    }

    public enum Format {
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

    public static func makeURL(format: Format) throws -> URL {
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
