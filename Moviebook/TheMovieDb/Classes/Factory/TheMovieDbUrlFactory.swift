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
    case movieWatchProviders(movieIdentifier: Movie.ID)
    case movieKeywords(movieIdentifier: Movie.ID)
    case movieCredits(movieIdentifier: Movie.ID)
    case movieGenres

    // MARK: Discover

    case movies(keywords: [MovieKeyword.ID], genres: [MovieGenre.ID], year: Int?, page: Int?)
    case discover(section: DiscoverMovieSection, genres: [MovieGenre.ID], year: Int?, page: Int?)

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
                URLQueryItem(name: "append_to_response", value: "credits,videos,keywords,release_dates")
            ])
        case .movieCollection(let identifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "collection/\(identifier)")
        case .movieWatchProviders(let movieIdentifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/watch/providers")
        case .movieKeywords(let movieIdentifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/keywords")
        case .movieCredits(let movieIdentifier):
            return try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/credits")
        case .movieGenres:
            return try TheMovieDbDataRequestFactory.makeURL(path: "genre/movie/list")
        case .movies(let keywords, let genres, let year, let page):
            var queryItems = [URLQueryItem]()
            if let page {
                queryItems.append(URLQueryItem(name: "page", value: String(page)))
            }
            if !keywords.isEmpty {
                let keywordsString = keywords
                    .map { String($0) }
                    .joined(separator: "|")
                queryItems.append(URLQueryItem(name: "with_keywords", value: keywordsString))
            }
            if !genres.isEmpty {
                let genresString = genres
                    .map { String($0) }
                    .joined(separator: "|")
                queryItems.append(URLQueryItem(name: "with_genres", value: genresString))
            }
            if let year {
                var components = DateComponents()
                components.year = year

                components.month = 0
                components.day = 1
                let dateFrom = Calendar.current.date(from: components)

                components.month = 11
                components.day = 31
                let dateTo = Calendar.current.date(from: components)

                let parsedDateFrom = TheMovieDbFactory.dateFormatter.string(for: dateFrom)
                let parsedDateTo = TheMovieDbFactory.dateFormatter.string(for: dateTo)

                queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: parsedDateFrom))
                queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: parsedDateTo))
            }
            return try TheMovieDbDataRequestFactory.makeURL(path: "discover/movie", queryItems: queryItems)
        case .discover(let section, let genres, let year, let page):
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
            if let year {
                var components = DateComponents()
                components.year = year

                components.month = 0
                components.day = 1
                let dateFrom = Calendar.current.date(from: components)

                components.month = 11
                components.day = 31
                let dateTo = Calendar.current.date(from: components)

                let parsedDateFrom = TheMovieDbFactory.dateFormatter.string(for: dateFrom)
                let parsedDateTo = TheMovieDbFactory.dateFormatter.string(for: dateTo)

                queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: parsedDateFrom))
                queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: parsedDateTo))
            }

            switch section {
            case .popular:
                queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
            case .topRated:
                queryItems.append(URLQueryItem(name: "sort_by", value: "vote_average.desc"))
                queryItems.append(URLQueryItem(name: "without_genres", value: "99,10755"))
                queryItems.append(URLQueryItem(name: "vote_count.gte", value: "200"))
            case .upcoming:
                queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
                queryItems.append(URLQueryItem(name: "with_release_type", value: "2|3"))

                if year == nil {
                    var dateToComponent = DateComponents()
                    dateToComponent.month = 5

                    let dateFrom = Date.now
                    let dateTo = Calendar.current.date(byAdding: dateToComponent, to: dateFrom)

                    let releaseDateGte = TheMovieDbFactory.dateFormatter.string(for: dateFrom)
                    let releaseDateLte = TheMovieDbFactory.dateFormatter.string(for: dateTo)

                    queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: releaseDateGte))
                    queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: releaseDateLte))
                }
            case .nowPlaying:
                queryItems.append(URLQueryItem(name: "sort_by", value: "popularity.desc"))
                queryItems.append(URLQueryItem(name: "with_release_type", value: "2|3"))

                if year == nil {
                    var component = DateComponents()
                    let currentDate = Date.now

                    component.month = -2
                    let dateFrom = Calendar.current.date(byAdding: component, to: currentDate)

                    component.month = 1
                    let dateTo = Calendar.current.date(byAdding: component, to: currentDate)

                    let releaseDateGte = TheMovieDbFactory.dateFormatter.string(for: dateFrom)
                    let releaseDateLte = TheMovieDbFactory.dateFormatter.string(for: dateTo)

                    queryItems.append(URLQueryItem(name: "primary_release_date.gte", value: releaseDateGte))
                    queryItems.append(URLQueryItem(name: "primary_release_date.lte", value: releaseDateLte))
                }
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
