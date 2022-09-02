//
//  UpcomingWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct UpcomingWebService {

    enum Error: Swift.Error {
        case cannotCreateURL
    }

    func fetch() async throws -> [MoviePreview] {
        guard let url = makeURL() else {
            throw Error.cannotCreateURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let parsedResponse = try JSONDecoder().decode(ResponseWithResults<MoviePreview>.self, from: data)

        return parsedResponse.results
    }

    private func makeURL(page: Int? = nil) -> URL? {
        let version = 3
        let path = "movie/upcoming"

        var queryItems = [URLQueryItem]()
        if let region = Locale.current.regionCode {
            queryItems.append(URLQueryItem(name: "region", value: region))
        }
        if let page = page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }

        var components = defaultURLComponents()
        components.path = "/\(version)/\(path)"
        components.queryItems?.append(contentsOf: queryItems)

        return components.url
    }

    private func defaultURLComponents() -> URLComponents {
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
