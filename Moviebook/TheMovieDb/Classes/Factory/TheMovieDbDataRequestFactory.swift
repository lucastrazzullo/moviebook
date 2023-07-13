//
//  TheMovieDbDataRequestFactory.swift
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
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "api_key", value: "9e718d9095bcf7e3e6dbe26672500060"),
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "include_adult", value: "false")
        ]

        if let region = Locale.current.region?.identifier {
            queryItems.append(URLQueryItem(name: "region", value: region))
        }
        
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.themoviedb.org"
        components.queryItems = queryItems
        return components
    }
}
