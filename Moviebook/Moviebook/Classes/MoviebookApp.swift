//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@MainActor final class Moviebook: ObservableObject {

    let watchlist: Watchlist

    private let storage: Storage

    init() {
        self.watchlist = Watchlist()
        self.storage = Storage(watchlist: watchlist)
        self.setupCache()
    }

    func start() async {
        do {
            try await storage.load()
        } catch {
            print(error)
        }
    }

    // MARK: Private helper methods

    private func setupCache() {
        URLCache.shared.memoryCapacity = 10_000_000
        URLCache.shared.diskCapacity = 1_000_000_000
    }
}

@main
struct MoviebookApp: App {

    @StateObject var application = Moviebook()

    let requestManager = DefaultRequestManager(logging: .disabled)

    var body: some Scene {
        WindowGroup {
            MoviebookView()
                .environment(\.requestManager, requestManager)
                .environmentObject(application.watchlist)
                .task { await application.start() }
        }
    }
}

private struct RequestManagerKey: EnvironmentKey {
    static let defaultValue: RequestManager = DefaultRequestManager(logging: .disabled)
}

extension EnvironmentValues {
    var requestManager: RequestManager {
        get { self[RequestManagerKey.self] }
        set { self[RequestManagerKey.self] = newValue }
    }
}
