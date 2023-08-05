//
//  WatchlistSectionViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/04/2023.
//

import Foundation
import Combine
import MoviebookCommon

@MainActor final class WatchlistViewModel: ObservableObject {

    // MARK: Published Properties

    @Published private(set) var isLoading: Bool = true
    @Published private(set) var error: WebServiceError? = nil

    // MARK: Private properties

    private var content: [WatchlistViewSectionContent] = []
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        content = WatchlistViewSection.allCases
            .map(WatchlistViewSectionContent.init(section:))
    }

    // MARK: Start

    func start(watchlist: Watchlist, requestLoader: RequestLoader) async {
        do {
            isLoading = true
            error = nil
            try await updateItems(watchlist.items, requestLoader: requestLoader)

            isLoading = false
            setupBindings(watchlist: watchlist, requestLoader: requestLoader)

        } catch let requestError {
            isLoading = false
            error = WebServiceError.failedToLoad(error: requestError, retry: { [weak self] in
                Task {
                    await self?.start(watchlist: watchlist, requestLoader: requestLoader)
                }
            })
        }
    }

    // MARK: Content

    func items(in section: WatchlistViewSection) -> [WatchlistViewItemGroup] {
        return content(for: section)?.groups ?? []
    }

    private func content(for section: WatchlistViewSection) -> WatchlistViewSectionContent? {
        return content.first(where: { $0.section == section })
    }

    private func updateItems(_ items: [WatchlistItem], requestLoader: RequestLoader) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            content.forEach { content in
                group.addTask {
                    try await content.updateItems(items, requestLoader: requestLoader)
                }
            }

            for try await _ in group {}
        }
    }

    // MARK: Sorting

    func sorting(in section: WatchlistViewSection) -> WatchlistViewSorting {
        return content(for: section)?.sorting ?? .lastAdded
    }

    func update(sorting: WatchlistViewSorting, in section: WatchlistViewSection) {
        Task {
            await content(for: section)?.updateSorting(sorting)
            objectWillChange.send()
        }
    }

    // MARK: Bindings

    private func setupBindings(watchlist: Watchlist, requestLoader: RequestLoader) {
        watchlist.itemWasRemoved
            .sink { [weak self] item in
                self?.content.forEach { $0.removeItem(item.id) }
                self?.objectWillChange.send()
            }
            .store(in: &subscriptions)

        watchlist.itemsDidChange
            .removeDuplicates()
            .sink { [weak self, weak requestLoader] items in
                guard let self, let requestLoader else { return }
                Task {
                    try await self.updateItems(items, requestLoader: requestLoader)
                    self.objectWillChange.send()
                }
            }
            .store(in: &subscriptions)
    }
}
