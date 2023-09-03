//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import CoreSpotlight
import MoviebookCommon

@MainActor private final class Moviebook: ObservableObject {

    @Published var watchlist: Watchlist?
    @Published var favourites: Favourites?
    @Published var error: Error?

    let notifications: Notifications = Notifications()

    private let storage: Storage = Storage()

    func start(requestLoader: RequestLoader) {
        Task {
            do {
                let watchlist = try await storage.loadWatchlist(requestLoader: requestLoader)
                let favourites = try await storage.loadFavourites()

                self.watchlist = watchlist
                self.favourites = favourites

                await self.notifications.schedule(for: watchlist, requestLoader: requestLoader)
            } catch {
                self.error = error
            }
        }
    }
}

@main
struct MoviebookApp: App {

    @Environment(\.requestLoader) private var requestLoader

    @StateObject private var application = Moviebook()
    @State private var presentedItem: NavigationItem? = nil

    var body: some Scene {
        WindowGroup {
            Group {
                if let watchlist = application.watchlist,
                   let favourites = application.favourites {
                    makeWatchlistView(
                        watchlist: watchlist,
                        favourites: favourites
                    )
                } else if let error = application.error {
                    makeErrorView(error: error)
                } else {
                    makeLoaderView()
                }
            }
            .onReceiveNotification(from: application.notifications, perform: openDeeplink(with:))
            .onOpenURL(perform: openDeeplink(with:))
            .onContinueUserActivity(CSSearchableItemActionType, perform: openDeeplink(with:))
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

    private func openDeeplink(with notification: UNNotification) {
        if let url = URL(string: notification.request.content.categoryIdentifier),
           let deeplink = Deeplink(rawValue: url) {
            open(deeplink: deeplink)
        }
    }

    private func open(deeplink: Deeplink) {
        if presentedItem != nil {
            presentedItem = nil
        }
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

    @ViewBuilder private func makeWatchlistView(watchlist: Watchlist, favourites: Favourites) -> some View {
        WatchlistView(presentedItem: $presentedItem)
            .sheet(item: $presentedItem) { item in
                Navigation(rootItem: item)
            }
            .environmentObject(watchlist)
            .environmentObject(favourites)
    }

    @ViewBuilder private func makeErrorView(error: Error) -> some View {
        RetriableErrorView(error: .failedToLoad(error: error) {
            application.start(requestLoader: requestLoader)
        })
    }

    @ViewBuilder private func makeLoaderView() -> some View {
        StartView {
            application.start(requestLoader: requestLoader)
        }
    }
}

// MARK: Environment

private struct RequestLoaderKey: EnvironmentKey {
    static let defaultValue: RequestLoader = DefaultRequestLoader()
}

private struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: ImageLoader = ImageLoader()
}

extension EnvironmentValues {

    var requestLoader: RequestLoader {
        get { self[RequestLoaderKey.self] }
        set { self[RequestLoaderKey.self] = newValue }
    }

    var imageLoader: ImageLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self ] = newValue}
    }
}
