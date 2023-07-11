//
//  ExploreContentViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 17/05/2023.
//

import Foundation
import MoviebookCommon

enum ExploreContentItems {
    case movies([MovieDetails])
    case artists([ArtistDetails])

    var isEmpty: Bool {
        switch self {
        case .movies(let array):
            return array.isEmpty
        case .artists(let array):
            return array.isEmpty
        }
    }

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
    var subtitle: String? { get }

    func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?)
}

@MainActor final class ExploreContentViewModel: ObservableObject, Identifiable {

    @Published var title: String
    @Published var subtitle: String?
    @Published var items: ExploreContentItems = .movies([])
    @Published var isLoading: Bool = false
    @Published var error: WebServiceError? = nil
    @Published var fetchNextPage: (() -> Void)?

    let dataProvider: ExploreContentDataProvider

    init(dataProvider: ExploreContentDataProvider) {
        self.dataProvider = dataProvider
        self.title = dataProvider.title
        self.subtitle = dataProvider.subtitle
    }

    func fetch(requestManager: RequestManager, page: Int? = nil) {
        Task {
            do {
                title = dataProvider.title
                subtitle = dataProvider.subtitle

                isLoading = true
                error = nil
                fetchNextPage = nil

                let response = try await self.dataProvider.fetch(requestManager: requestManager, page: page)
                if let nextPage = response.nextPage {
                    fetchNextPage = { [weak self] in self?.fetch(requestManager: requestManager, page: nextPage) }
                }

                if page == nil {
                    items = response.results
                } else {
                    items = items.appending(items: response.results)
                }

                isLoading = false

            } catch {
                self.isLoading = false
                self.error = .failedToLoad(id: .init()) { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.fetch(requestManager: requestManager, page: page)
                    }
                }
            }
        }
    }
}
