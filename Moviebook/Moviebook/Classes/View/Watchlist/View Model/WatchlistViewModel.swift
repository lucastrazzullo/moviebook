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

    // MARK: Instance Properties

    var items: [WatchlistViewItem] {
        return content.first(where: { $0.section == section })?.items ?? []
    }

    var sorting: WatchlistViewSorting {
        return content.first(where: { $0.section == section })?.sorting ?? .lastAdded
    }

    @Published var section: WatchlistViewSection
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var error: WebServiceError? = nil

    private var content: [WatchlistViewSectionContent] = []
    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        section = .toWatch
        content = WatchlistViewSection.allCases.map(WatchlistViewSectionContent.init(section:))
    }

    // MARK: Internal methods

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

    func update(sorting: WatchlistViewSorting) {
        content.first(where: { $0.section == section })?.updateSorting(sorting)
        objectWillChange.send()
    }

    // MARK: Private methods

    private func setupBindings(watchlist: Watchlist, requestLoader: RequestLoader) {
        watchlist.itemWasRemoved
            .sink { [weak self] item in
                self?.content.forEach { $0.removeItem(item.id) }
            }
            .store(in: &subscriptions)

        watchlist.itemsDidChange
            .removeDuplicates()
            .sink { [weak self, weak requestLoader] items in
                guard let self, let requestLoader else { return }
                Task {
                    try await self.updateItems(items, requestLoader: requestLoader)
                }
            }
            .store(in: &subscriptions)
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
}
