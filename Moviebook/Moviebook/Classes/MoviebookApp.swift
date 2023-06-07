//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import CoreSpotlight

@MainActor private final class Moviebook: ObservableObject {

    @Published var watchlist: Watchlist?
    @Published var error: Error?

    private let storage: Storage = Storage()

    func start() async {
        do {
            self.watchlist = try await storage.loadWatchlist()
        } catch {
            self.error = error
        }
    }
}

@main
struct MoviebookApp: App {

    @StateObject private var application = Moviebook()

    @State private var presentedItemNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if let watchlist = application.watchlist {
                    makeWatchlistView(watchlist: watchlist)
                } else if let error = application.error {
                    makeErrorView(error: error)
                } else {
                    makeLoaderView()
                }
            }
            .onOpenURL(perform: openDeeplink(with:))
            .onContinueUserActivity(CSSearchableItemActionType, perform: openDeeplink(with:))
            .task { await application.start() }
        }
    }

    // MARK: Deeplinking

    private func openDeeplink(with url: URL) {
        if let deeplink = Deeplink(rawValue: url) {
            open(deeplink: deeplink)
        }
    }

    private func openDeeplink(with userActivity: NSUserActivity) {
        if let deeplink = Spotlight.deeplink(from: userActivity) {
            open(deeplink: deeplink)
        }
    }

    private func open(deeplink: Deeplink) {
        switch deeplink {
        case .watchlist:
            presentedItem = nil
        case .movie(let identifier):
            presentedItem = .movieWithIdentifier(identifier)
        case .artist(let identifier):
            presentedItem = .artistWithIdentifier(identifier)
        }
    }

    // MARK: View building

    @ViewBuilder private func makeWatchlistView(watchlist: Watchlist) -> some View {
        Group {
            WatchlistView()
                .sheet(item: $presentedItem) { item in
                    Navigation(path: $presentedItemNavigationPath, presentingItem: item)
                }
        }
        .environmentObject(watchlist)
    }

    @ViewBuilder private func makeErrorView(error: Error) -> some View {
        RetriableErrorView {
            Task { await application.start() }
        }
    }

    @ViewBuilder private func makeLoaderView() -> some View {
        LoaderView()
    }
}

// MARK: Environment

private struct RequestManagerKey: EnvironmentKey {
    static let defaultValue: RequestManager = DefaultRequestManager(logging: .disabled)
}

extension EnvironmentValues {

    var requestManager: RequestManager {
        get { self[RequestManagerKey.self] }
        set { self[RequestManagerKey.self] = newValue }
    }
}
