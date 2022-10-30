//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@MainActor enum Globals {
  static let watchlist = Watchlist(storage: UserDefaultsWatchlistStorage())
}

@main
struct MoviebookApp: App {

    let requestManager = DefaultRequestManager.shared
    let user = User(watchlist: Globals.watchlist)

    var body: some Scene {
        WindowGroup {
            MoviebookView()
                .environment(\.requestManager, requestManager)
                .environmentObject(user.watchlist)
        }
    }
}

private struct RequestManagerKey: EnvironmentKey {
    static let defaultValue = DefaultRequestManager.shared
}

extension EnvironmentValues {
    var requestManager: RequestManager {
        get { self[RequestManagerKey.self] }
        set { self[RequestManagerKey.self] = newValue }
    }
}
