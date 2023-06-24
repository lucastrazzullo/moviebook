//
//  TheMovieDbUrlFactory.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

public enum TheMovieDbUrlFactory {

    // MARK: Movie

    case movie(identifier: Movie.ID)
    case mocieCollection(identifier: MovieCollection.ID)
    case watchProviders(movieIdentifier: Movie.ID)
    case popularMovies(page: Int?)
    case upcomingMovies(page: Int?)
    case topRatedMovies(page: Int?)
    case nowPlayingMovies(page: Int?)

    // MARK: Artist

    case artist(identifier: Artist.ID)

    // MARK: Search

    case searchMovie(keyword: String, page: Int?)
    case searchPerson(keyword: String, page: Int?)

    // MARK: - Public properties

    public func makeUrl() throws -> URL {
        switch self {
        case .movie(let identifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(identifier)", queryItems: [
                URLQueryItem(name: "append_to_response", value: "credits,videos")
            ])
        case .mocieCollection(let identifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "collection/\(identifier)")
        case .watchProviders(let movieIdentifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/watch/providers")
        case .popularMovies(let page):
            return try Self.makePagedUrl(path: "movie/popular", page: page)
        case .upcomingMovies(let page):
            return try Self.makePagedUrl(path: "movie/upcoming", page: page)
        case .topRatedMovies(let page):
            return try Self.makePagedUrl(path: "movie/top_rated", page: page)
        case .nowPlayingMovies(let page):
            return try Self.makePagedUrl(path: "movie/now_playing", page: page)
        case .artist(let identifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "person/\(identifier)", queryItems: [
                URLQueryItem(name: "append_to_response", value: "credits")
            ])
        case .searchMovie(let keyword, let page):
            var queryItems = [URLQueryItem(name: "query", value: keyword)]
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: String(page)))
            }
            return try TheMovieDbDataRequestFactory.makeURL(path: "search/movie", queryItems: queryItems)
        case .searchPerson(let keyword, let page):
            var queryItems = [URLQueryItem(name: "query", value: keyword)]
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: String(page)))
            }
            return try TheMovieDbDataRequestFactory.makeURL(path: "search/person", queryItems: queryItems)
        }
    }

    // MARK: - Private helper methods

    private static func makePagedUrl(path: String, page: Int?) throws -> URL {
        var queryItems = [URLQueryItem]()
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        return try TheMovieDbDataRequestFactory.makeURL(path: path, queryItems: queryItems)
    }
}
