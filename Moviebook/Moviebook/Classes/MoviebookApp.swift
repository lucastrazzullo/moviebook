//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@main
struct MoviebookApp: App {

    @StateObject var watchlist = Watchlist(storage: FileBasedWatchlistStorage())

    let requestManager = DefaultRequestManager(logging: .disabled)

    var body: some Scene {
        WindowGroup {
            MoviebookView()
                .onAppear {
                    URLCache.shared.memoryCapacity = 10_000_000
                    URLCache.shared.diskCapacity = 1_000_000_000
                }
                .environment(\.requestManager, requestManager)
                .environmentObject(watchlist)
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
