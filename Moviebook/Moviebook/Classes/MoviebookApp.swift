//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

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

@main
struct MoviebookApp: App {

    @StateObject var application = Moviebook()

    let requestManager = DefaultRequestManager(logging: .disabled)

    var body: some Scene {
        WindowGroup {
            Group {
                if let watchlist = application.watchlist {
                    MoviebookView()
                        .environment(\.requestManager, requestManager)
                        .environmentObject(watchlist)
                } else if let _ = application.error {
                    RetriableErrorView {
                        Task { await application.start() }
                    }
                } else {
                    LoaderView()
                }
            }
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
