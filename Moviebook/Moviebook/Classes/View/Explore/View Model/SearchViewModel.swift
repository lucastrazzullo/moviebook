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

    final class DataProvider: ObservableObject, ExploreContentDataProvider {

        enum Scope: String, CaseIterable, Hashable {
            case movie
            case artist
        }

        @Published var searchScope: Scope = .movie
        @Published var searchKeyword: String = ""

        init(searchScope: Scope, searchKeyword: String?) {
            self.searchScope = searchScope
            self.searchKeyword = searchKeyword ?? ""
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

    @Published var dataProvider: DataProvider
    @Published var content: ExploreContentViewModel

    private var subscriptions: Set<AnyCancellable> = []

    init(scope: DataProvider.Scope, query: String?) {
        let dataProvider = DataProvider(searchScope: scope, searchKeyword: query)
        self.dataProvider = dataProvider
        self.content = ExploreContentViewModel(title: NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: ""), dataProvider: dataProvider)
    }

    // MARK: Search

    func start(requestManager: RequestManager) {
        Publishers.CombineLatest(dataProvider.$searchKeyword, dataProvider.$searchScope)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self, weak requestManager] keyword, scope in
                if let requestManager, let self {
                    self.content.fetch(requestManager: requestManager)
                }
            })
            .store(in: &subscriptions)
    }
}
