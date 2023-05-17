//
//  SearchViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine
import CoreSpotlight

@MainActor final class SearchViewModel: ObservableObject {

    enum Scope: String, CaseIterable {
        case movie
        case artist
    }

    // MARK: Instance Properties

    var title: String {
        return Self.defaultTitle + ": " + searchKeyword
    }

    var fetchResults: ExploreContentViewModel.FetchResults {
        return { [weak self] requestManager, page in
            guard let self else { return try await Self.defaultFetchResults(requestManager, page) }
            let webService = SearchWebService(requestManager: requestManager)
            switch self.searchScope {
            case .movie:
                let response = try await webService.fetchMovies(with: searchKeyword, page: page)
                return (results: .movies(response.results), nextPage: response.nextPage)
            case .artist:
                let response = try await webService.fetchArtists(with: searchKeyword, page: page)
                return (results: .artists(response.results), nextPage: response.nextPage)
            }
        }
    }

    @Published var searchKeyword: String = ""
    @Published var searchScope: Scope = .movie
    @Published var content: ExploreContentViewModel

    private var subscriptions: Set<AnyCancellable> = []

    private static let defaultTitle: String = NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "")
    private static let defaultFetchResults: ExploreContentViewModel.FetchResults = { _, _ in (results: .movies([]), nextPage: nil) }

    init(scope: Scope, query: String?) {
        self.content = ExploreContentViewModel(title: Self.defaultTitle, fetchResults: Self.defaultFetchResults)
        self.searchScope = scope

        if let query {
            self.searchKeyword = query
        }
    }

    // MARK: Search

    func start(requestManager: RequestManager) {
        Publishers.CombineLatest($searchKeyword, $searchScope)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self, weak requestManager] keyword, scope in
                if let requestManager, let self {
                    self.content.title = self.title
                    self.content.fetchResults = self.fetchResults
                    self.content.fetch(requestManager: requestManager)
                }
            })
            .store(in: &subscriptions)
    }
}
