//
//  ExploreContentViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 17/05/2023.
//

import Foundation

@MainActor
final class ExploreContentViewModel: ObservableObject, Identifiable {

    typealias FetchResults = (RequestManager, Int?) async throws -> (results: [MovieDetails], nextPage: Int?)

    var fetchResults: FetchResults

    @Published var title: String
    @Published var items: [MovieDetails] = []
    @Published var isLoading: Bool = false
    @Published var error: WebServiceError? = nil
    @Published var fetchNextPage: (() -> Void)?

    init(title: String, fetchResults: @escaping FetchResults) {
        self.title = title
        self.fetchResults = fetchResults
    }

    func fetch(requestManager: RequestManager, page: Int? = nil) {
        Task {
            do {
                isLoading = true
                error = nil
                fetchNextPage = nil

                let result = try await self.fetchResults(requestManager, page)
                if let nextPage = result.nextPage {
                    fetchNextPage = { [weak self] in self?.fetch(requestManager: requestManager, page: nextPage) }
                }

                items = items + result.results
                isLoading = false

            } catch {
                self.isLoading = false
                self.error = .failedToLoad(id: .init()) { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.fetch(requestManager: requestManager)
                    }
                }
            }
        }
    }
}
