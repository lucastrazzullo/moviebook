//
//  Moviebook.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/05/2023.
//

import Foundation
import Combine

@MainActor final class Moviebook: ObservableObject {

    @Published var watchlist: Watchlist?
    @Published var watchlistPrompt: WatchlistPrompt?
    @Published var error: Error?

    private let storage: Storage
    private var subscriptions: Set<AnyCancellable> = []

    init() {
        self.storage = Storage()
        self.setupCache()
    }

    func start() async {
        do {
            self.watchlist = try await storage.loadWatchlist()
            self.watchlist?.itemDidUpdateState
                .sink { [weak self] item in
                    self?.watchlistPrompt = WatchlistPrompt(item: item)
                }
                .store(in: &subscriptions)

        } catch {
            self.error = error
        }
    }

    // MARK: Private helper methods

    private func setupCache() {
        URLCache.shared.memoryCapacity = 10_000_000
        URLCache.shared.diskCapacity = 1_000_000_000
    }
}
