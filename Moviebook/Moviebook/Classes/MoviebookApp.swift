//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@main
struct MoviebookApp: App {

    let requestManager = DefaultRequestManager.shared
    let user = User.shared

    var body: some Scene {
        WindowGroup {
            FeedView()
                .environment(\.requestManager, requestManager)
                .environmentObject(user)
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
