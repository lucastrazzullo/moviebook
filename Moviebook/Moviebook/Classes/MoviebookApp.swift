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

    enum State: Equatable {

        static func == (lhs: Moviebook.State, rhs: Moviebook.State) -> Bool {
            lhs.id == rhs.id
        }

        case ready(watchlist: Watchlist, favourites: Favourites)
        case error(error: Error)
        case loading

        var id: String {
            switch self {
            case .ready:
                return "ready"
            case .error:
                return "error"
            case .loading:
                return "loading"
            }
        }
    }

    @Published private(set) var state: State = .loading

    let notifications: Notifications = Notifications()

    private let storage: Storage = Storage()

    func start(requestLoader: RequestLoader) {
        Task {
            do {
                let watchlist = try await storage.loadWatchlist(requestLoader: requestLoader)
                let favourites = try await storage.loadFavourites()

                self.state = .ready(watchlist: watchlist, favourites: favourites)
                await self.notifications.schedule(for: watchlist, requestLoader: requestLoader)
            } catch {
                self.state = .error(error: error)
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
                switch application.state {
                case .ready(let watchlist, let favourites):
                    WatchlistView(presentedItem: $presentedItem)
                        .sheet(item: $presentedItem) { item in
                            Navigation(rootItem: item)
                        }
                        .environmentObject(watchlist)
                        .environmentObject(favourites)
                case .error(let error):
                    RetriableErrorView(error: .failedToLoad(error: error) {
                        application.start(requestLoader: requestLoader)
                    })
                case .loading:
                    StartView {
                        application.start(requestLoader: requestLoader)
                    }
                }
            }
            .animation(.default, value: application.state)
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
