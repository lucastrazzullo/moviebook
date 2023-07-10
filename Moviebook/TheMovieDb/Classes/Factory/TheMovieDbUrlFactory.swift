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
    case movieCollection(identifier: MovieCollection.ID)
    case watchProviders(movieIdentifier: Movie.ID)
    case movieGenres

    // MARK: Discover

    case movies(genres: [MovieGenre.ID], page: Int?)
    case discover(section: DiscoverMovieSection, genres: [MovieGenre.ID], page: Int?)

    // MARK: Artist

    case artist(identifier: Artist.ID)
    case popularArtists(page: Int?)

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
        case .movieCollection(let identifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "collection/\(identifier)")
        case .watchProviders(let movieIdentifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/watch/providers")
        case .movieGenres:
            return try TheMovieDbDataRequestFactory.makeURL(path: "genre/movie/list")
        case .movies(let genres, let page):
            var queryItems = [URLQueryItem]()
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: String(page)))
            }
            if !genres.isEmpty {
                let genresString = genres
                    .map { String($0) }
                    .joined(separator: ",")
                queryItems.append(URLQueryItem(name: "with_genres", value: genresString))
            }
            return try TheMovieDbDataRequestFactory.makeURL(path: "discover/movie", queryItems: queryItems)
        case .discover(let section, let genres, let page):
            var queryItems = [URLQueryItem]()
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: String(page)))
            }
            if !genres.isEmpty {
                let genresString = genres
                    .map { String($0) }
                    .joined(separator: ",")
                queryItems.append(URLQueryItem(name: "with_genres", value: genresString))
            }
            switch section {
            case .popular:
                queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            case .topRated:
                queryItems.append(URLQueryItem(name: "sort_by", value: "vote_average.desc"))
                queryItems.append(URLQueryItem(name: "without_genres", value: "99,10755"))
                queryItems.append(URLQueryItem(name: "vote_count.gte", value: "200"))
            case .upcoming:
                var laterDateComponent = DateComponents()
                laterDateComponent.month = 5

                let currentDate = Date.now
                let laterDate = Calendar.current.date(byAdding: laterDateComponent, to: currentDate)

                let releaseDateGte = TheMovieDbFactory.dateFormatter.string(for: currentDate)
                let releaseDateLte = TheMovieDbFactory.dateFormatter.string(for: laterDate)

                queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
                queryItems.append(URLQueryItem(name: "with_release_type", value: "2|3"))
                queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: releaseDateGte))
                queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: releaseDateLte))
            case .nowPlaying:
                var earlierDateComponent = DateComponents()
                earlierDateComponent.month = -2

                var laterDateComponent = DateComponents()
                laterDateComponent.month = 1

                let currentDate = Date.now
                let earlierDate = Calendar.current.date(byAdding: earlierDateComponent, to: currentDate)
                let laterDate = Calendar.current.date(byAdding: laterDateComponent, to: currentDate)

                let releaseDateGte = TheMovieDbFactory.dateFormatter.string(for: earlierDate)
                let releaseDateLte = TheMovieDbFactory.dateFormatter.string(for: laterDate)

                queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
                queryItems.append(URLQueryItem(name: "with_release_type", value: "2|3"))
                queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: releaseDateGte))
                queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: releaseDateLte))
            }
            return try TheMovieDbDataRequestFactory.makeURL(path: "discover/movie", queryItems: queryItems)
        case .artist(let identifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "person/\(identifier)", queryItems: [
                URLQueryItem(name: "append_to_response", value: "credits")
            ])
        case .popularArtists(let page):
            var queryItems = [URLQueryItem]()
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: String(page)))
            }
            return try TheMovieDbDataRequestFactory.makeURL(path: "person/popular", queryItems: queryItems)
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
}
