//
//  SearchDataProvider.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 13/07/2023.
//

import Foundation
import MoviebookCommon

final class SearchDataProvider: ExploreContentDataProvider {

    enum Scope: String, CaseIterable, Hashable {
        case movie
        case artist
    }

    var searchScope: Scope
    var searchKeyword: String

    init(searchScope: Scope, searchKeyword: String) {
        self.searchScope = searchScope
        self.searchKeyword = searchKeyword
    }

    func fetch(requestLoader: RequestLoader, page: Int?) async throws -> ExploreContentDataProvider.Response {
        let webService = WebService.searchWebService(requestLoader: requestLoader)
        switch searchScope {
        case .movie:
            let response = try await webService.fetchMovies(with: searchKeyword, page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        case .artist:
            let response = try await webService.fetchArtists(with: searchKeyword, page: page)
            return (results: .artists(response.results), nextPage: response.nextPage)
        }
    }
}
