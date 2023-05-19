//
//  Moviebook.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/05/2023.
//

import Foundation

@MainActor final class Moviebook: ObservableObject {

    @Published var watchlist: Watchlist?
    @Published var error: Error?

    private let storage: Storage

    init() {
        self.storage = Storage()
        self.setupCache()
    }

    func start() async {
        do {
            self.watchlist = try await storage.loadWatchlist()
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
