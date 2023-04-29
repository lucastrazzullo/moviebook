//
//  Deeplink.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/04/2023.
//

import Foundation

enum Deeplink: RawRepresentable {

    typealias RawValue = URL

    // MARK: Cases

    case watchlist
    case search(query: String?)
    case movie(identifier: Movie.ID)
    case artist(identifier: Artist.ID)

    // MARK: Types

    private enum Screen: String {
        case watchlist = "watchlist"
        case search = "search"
        case movie = "movie"
        case artist = "artist"

        // Legacy screens
        case feed = "feed"
        case actor = "actor"

        init(deeplink: Deeplink) {
            switch deeplink {
            case .watchlist:
                self = .watchlist
            case .search:
                self = .search
            case .movie:
                self = .movie
            case .artist:
                self = .artist
            }
        }
    }

    // MARK: Type Properties

    private static let scheme = "https"
    private static let host = "moviebook.org"

    // MARK: Instance Properties

    private var path: String {
        let screen = Screen(deeplink: self)
        switch self {
        case .watchlist:
            return screen.rawValue
        case .search(let query):
            if let query = query {
                return "\(screen.rawValue)/\(query)"
            } else {
                return "\(screen.rawValue)"
            }
        case .movie(let identifier):
            return "\(screen.rawValue)/\(identifier)"
        case .artist(let identifier):
            return "\(screen.rawValue)/\(identifier)"
        }
    }

    var rawValue: URL {
        return URL(string: "\(Self.scheme)://\(Self.host)/\(path)")!
    }

    // MARK: Object life cycle

    init?(rawValue: URL) {
        let components = rawValue.pathComponents
        guard components.indices.contains(1), let screen = Screen(rawValue: components[1]) else {
            return nil
        }

        let identifier = components.indices.contains(2) ? components[2] : nil

        switch screen {
        case .watchlist, .feed:
            self = .watchlist
        case .search:
            self = .search(query: identifier)
        case .movie where identifier != nil && Movie.ID(identifier!) != nil:
            self = .movie(identifier: Movie.ID(identifier!)!)
        case .artist where identifier != nil && Artist.ID(identifier!) != nil,
             .actor where identifier != nil && Artist.ID(identifier!) != nil:
            self = .artist(identifier: Artist.ID(identifier!)!)
        default:
            return nil
        }
    }
}
