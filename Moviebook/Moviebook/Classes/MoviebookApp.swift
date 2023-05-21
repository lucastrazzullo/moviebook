//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@main
struct MoviebookApp: App {

    @StateObject var application = Moviebook()

    var body: some Scene {
        WindowGroup {
            Group {
                if let watchlist = application.watchlist {
                    MoviebookView()
                        .environmentObject(watchlist)
                        .environment(\.watchlistPrompt, application.watchlistPrompt)
                } else if let _ = application.error {
                    RetriableErrorView { Task { await application.start() }}
                } else {
                    LoaderView()
                }
            }
            .task { await application.start() }
        }
    }
}

// MARK: Environment

private struct RequestManagerKey: EnvironmentKey {
    static let defaultValue: RequestManager = DefaultRequestManager(logging: .disabled)
}

private struct WatchlistPromptKey: EnvironmentKey {
    static let defaultValue: WatchlistPrompt? = nil
}

extension EnvironmentValues {

    var requestManager: RequestManager {
        get { self[RequestManagerKey.self] }
        set { self[RequestManagerKey.self] = newValue }
    }

    var watchlistPrompt: WatchlistPrompt? {
        get { self[WatchlistPromptKey.self] }
        set { self[WatchlistPromptKey.self] = newValue }
    }
}
