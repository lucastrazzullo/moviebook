//
//  SearchViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine
import CoreSpotlight
import MoviebookCommon

@MainActor final class SearchViewModel: ObservableObject {

    final class Search: ObservableObject, ExploreContentDataProvider {

        enum Scope: String, CaseIterable, Hashable {
            case movie
            case artist
        }

        var title: String {
            NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "")
        }

        let subtitle: String? = nil

        var searchScope: Scope
        var searchKeyword: String

        init(searchScope: Scope, searchKeyword: String) {
            self.searchScope = searchScope
            self.searchKeyword = searchKeyword
        }

        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let webService = WebService.searchWebService(requestManager: requestManager)
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

    // MARK: Instance Properties

    @Published var searchScope: Search.Scope = .movie
    @Published var searchKeyword: String

    let content: ExploreContentViewModel

    private let search: Search
    private var subscriptions: Set<AnyCancellable> = []

    init(scope: Search.Scope, query: String) {
        self.searchScope = scope
        self.searchKeyword = query

        self.search = Search(searchScope: scope, searchKeyword: query)
        self.content = ExploreContentViewModel(dataProvider: search)
    }

    // MARK: Search

    func start(requestManager: RequestManager) {
        Publishers.CombineLatest($searchKeyword, $searchScope)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self, weak requestManager] keyword, scope in
                guard let self, let requestManager else { return }

                self.search.searchKeyword = keyword
                self.search.searchScope = scope

                self.content.fetch(requestManager: requestManager)
            })
            .store(in: &subscriptions)
    }
}
