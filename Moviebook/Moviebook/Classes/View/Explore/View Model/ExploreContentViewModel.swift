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
    func fetch(requestLoader: RequestLoader, page: Int?) async throws -> Response
}

@MainActor final class ExploreContentViewModel: ObservableObject, Identifiable {

    let title: String
    let subtitle: String?

    @Published private(set) var items: ExploreContentItems = .movies([])
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: WebServiceError? = nil
    @Published private(set) var fetchNextPage: (() -> Void)?

    let dataProvider: ExploreContentDataProvider

    init(dataProvider: ExploreContentDataProvider, title: String, subtitle: String?, items: ExploreContentItems) {
        self.dataProvider = dataProvider
        self.title = title
        self.subtitle = subtitle
        self.items = items
    }

    func fetch(requestLoader: RequestLoader, page: Int? = nil, updateDataProvider: @escaping (ExploreContentDataProvider) async -> Void) async {
        isLoading = true
        await updateDataProvider(dataProvider)
        await fetch(requestLoader: requestLoader, page: page)
    }

    private func fetch(requestLoader: RequestLoader, page: Int? = nil) async {
        do {
            isLoading = true
            error = nil
            fetchNextPage = nil

            let response = try await self.dataProvider.fetch(requestLoader: requestLoader, page: page)
            if let nextPage = response.nextPage {
                fetchNextPage = { [weak self] in
                    Task {
                        await self?.fetch(requestLoader: requestLoader, page: nextPage)
                    }
                }
            }

            if page == nil {
                items = response.results
            } else {
                items = items.appending(items: response.results)
            }

            isLoading = false

        } catch let requestError {
            isLoading = false
            error = .failedToLoad(error: requestError) { [weak self, weak requestLoader] in
                if let requestLoader {
                    Task {
                        await self?.fetch(requestLoader: requestLoader, page: page)
                    }
                }
            }
        }
    }
}
