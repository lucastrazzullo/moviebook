//
//  ExploreSearchViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine
import CoreSpotlight

@MainActor final class ExploreSearchViewModel: ObservableObject {

    enum Scope: String, CaseIterable {
        case movie
        case artist
    }

    enum SearchItems {
        case movies([MovieDetails])
        case artists([ArtistDetails])

        func appending(items: SearchItems) -> Self {
            switch (self, items) {
            case (let .movies(movies), let .movies(newMovies)):
                return .movies(movies + newMovies)
            case (let .artists(artists), let .artists(newArtists)):
                return .artists(artists + newArtists)
            default:
                return items
            }
        }
    }

    // MARK: Instance Properties

    var title: String {
        return NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "") + ": " + searchKeyword
    }

    @Published var searchKeyword: String = ""
    @Published var searchScope: Scope = .movie

    @Published var result: SearchItems = .movies([])
    @Published var isLoading: Bool = false
    @Published var error: WebServiceError? = nil
    @Published var fetchNextPage: (() -> Void)?

    private var subscriptions: Set<AnyCancellable> = []

    init(scope: Scope, query: String?) {
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
                if let requestManager {
                    self?.fetchResults(for: keyword, scope: scope, page: nil, requestManager: requestManager)
                }
            })
            .store(in: &subscriptions)
    }

    private func fetchResults(for keyword: String, scope: Scope, page: Int?, requestManager: RequestManager) {
        Task {
            do {
                isLoading = true
                error = nil
                fetchNextPage = nil

                let webService = SearchWebService(requestManager: requestManager)
                let nextPage: Int?
                let items: SearchItems
                switch scope {
                case .movie:
                    let response = try await webService.fetchMovies(with: keyword, page: page)
                    nextPage = response.nextPage
                    items = .movies(response.results.sorted(by: { $0.release > $1.release }))
                case .artist:
                    let response = try await webService.fetchArtists(with: keyword, page: page)
                    nextPage = response.nextPage
                    items = .artists(response.results.sorted(by: { $0.popularity > $1.popularity }))
                }

                if let nextPage {
                    fetchNextPage = { [weak self] in
                        self?.fetchResults(for: keyword, scope: scope, page: nextPage, requestManager: requestManager)
                    }
                }
                result = result.appending(items: items)
                isLoading = false

            } catch {
                self.isLoading = false
                self.error = .failedToLoad(id: .init()) { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.fetchResults(for: keyword, scope: scope, page: page, requestManager: requestManager)
                    }
                }
            }
        }
    }
}
