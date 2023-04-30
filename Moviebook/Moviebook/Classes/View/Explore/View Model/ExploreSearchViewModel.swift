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

    // MARK: Instance Properties

    var title: String {
        return NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "") + ": " + searchKeyword
    }

    @Published var searchKeyword: String = ""
    @Published var searchScope: Scope = .movie

    @Published var result: ExploreListItems = .movies([])
    @Published var isLoading: Bool = false
    @Published var error: WebServiceError? = nil

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
                    self?.fetchMovies(for: keyword, scope: scope, requestManager: requestManager)
                }
            })
            .store(in: &subscriptions)
    }

    private func fetchMovies(for keyword: String, scope: Scope, requestManager: RequestManager) {
        Task {
            do {
                error = nil
                isLoading = true
                switch scope {
                case .movie:
                    let movies = try await SearchWebService(requestManager: requestManager)
                        .fetchMovies(with: keyword)
                    result = ExploreListItems.movies(movies)
                case .artist:
                    let artists = try await SearchWebService(requestManager: requestManager)
                        .fetchArtists(with: keyword)
                    result = ExploreListItems.artists(artists)
                }
                isLoading = false
            } catch {
                self.isLoading = false
                self.error = .failedToLoad(id: .init()) { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.fetchMovies(for: keyword, scope: scope, requestManager: requestManager)
                    }
                }
            }
        }
    }
}
