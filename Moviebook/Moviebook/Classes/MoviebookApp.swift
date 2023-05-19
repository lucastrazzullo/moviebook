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
