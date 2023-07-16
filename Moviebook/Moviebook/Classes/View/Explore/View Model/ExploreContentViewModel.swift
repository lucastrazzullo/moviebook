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

    var count: Int {
        switch self {
        case .movies(let array):
            return array.count
        case .artists(let array):
            return array.count
        }
    }

    func appending(items: ExploreContentItems) -> Self {
        switch (self, items) {
        case (let .movies(movies), let .movies(newMovies)):
            return .movies((movies + newMovies).removeDuplicates(where: { $0.id == $1.id }))
        case (let .artists(artists), let .artists(newArtists)):
            return .artists((artists + newArtists).removeDuplicates(where: { $0.id == $1.id }))
        default:
            return items
        }
    }
}

protocol ExploreContentDataProvider {
    typealias Response = (results: ExploreContentItems, nextPage: Int?)

    var title: String { get }
    var subtitle: String? { get }

    func fetch(requestManager: RequestManager, page: Int?) async throws -> Response
}

@MainActor final class ExploreContentViewModel: ObservableObject, Identifiable {

    @Published private(set) var title: String
    @Published private(set) var subtitle: String?
    @Published private(set) var items: ExploreContentItems = .movies([])
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: WebServiceError? = nil
    @Published private(set) var fetchNextPage: (() -> Void)?

    let dataProvider: ExploreContentDataProvider

    init(dataProvider: ExploreContentDataProvider, items: ExploreContentItems) {
        self.dataProvider = dataProvider
        self.title = dataProvider.title
        self.subtitle = dataProvider.subtitle
        self.items = items
    }

    func fetch(requestManager: RequestManager, page: Int? = nil, updateDataProvider: @escaping (ExploreContentDataProvider) async -> Void) async {
        isLoading = true
        await updateDataProvider(dataProvider)
        await fetch(requestManager: requestManager, page: page)
    }

    private func fetch(requestManager: RequestManager, page: Int? = nil) async {
        do {
            title = dataProvider.title
            subtitle = dataProvider.subtitle

            isLoading = true
            error = nil
            fetchNextPage = nil

            let response = try await self.dataProvider.fetch(requestManager: requestManager, page: page)
            if let nextPage = response.nextPage {
                fetchNextPage = { [weak self] in
                    Task {
                        await self?.fetch(requestManager: requestManager, page: nextPage)
                    }
                }
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
                    Task {
                        await self?.fetch(requestManager: requestManager, page: page)
                    }
                }
            }
        }
    }
}
