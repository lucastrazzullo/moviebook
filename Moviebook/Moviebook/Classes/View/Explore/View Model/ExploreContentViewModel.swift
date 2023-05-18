//
//  ExploreContentViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 17/05/2023.
//

import Foundation

enum ExploreContentItems {
    case movies([MovieDetails])
    case artists([ArtistDetails])

    func appending(items: ExploreContentItems) -> Self {
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

protocol ExploreContentDataProvider {
    var title: String { get }
    func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?)
}

@MainActor
final class ExploreContentViewModel: ObservableObject, Identifiable {

    let dataProvider: ExploreContentDataProvider

    @Published var title: String
    @Published var items: ExploreContentItems = .movies([])
    @Published var isLoading: Bool = false
    @Published var error: WebServiceError? = nil
    @Published var fetchNextPage: (() -> Void)?

    init(dataProvider: ExploreContentDataProvider) {
        self.title = dataProvider.title
        self.dataProvider = dataProvider
    }

    func fetch(requestManager: RequestManager, page: Int? = nil) {
        Task {
            do {
                isLoading = true
                error = nil
                fetchNextPage = nil

                title = dataProvider.title
                let response = try await self.dataProvider.fetch(requestManager: requestManager, page: page)
                if let nextPage = response.nextPage {
                    fetchNextPage = { [weak self] in self?.fetch(requestManager: requestManager, page: nextPage) }
                }

                items = items.appending(items: response.results)
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
