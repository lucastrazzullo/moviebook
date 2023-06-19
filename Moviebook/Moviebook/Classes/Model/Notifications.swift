//
//  Notifications.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 19/06/2023.
//

import Foundation
import Combine
import UserNotifications
import MoviebookCommons

actor Notifications {

    private let requestManager: RequestManager
    private var subscriptions: Set<AnyCancellable> = []

    init(watchlist: Watchlist, requestManager: RequestManager) {
        self.requestManager = requestManager

        Task {
            await self.schedule(for: watchlist)
        }
    }

    // MARK: Private scheduling methods

    private func schedule(for watchlist: Watchlist) async {
        await watchlist.itemDidUpdateState
            .sink { item in Task { try await self.schedule(for: item) }}
            .store(in: &subscriptions)

        await watchlist.itemWasRemoved
            .sink { item in Task { await self.remove(for: item) }}
            .store(in: &subscriptions)
    }

    private func schedule(for item: WatchlistItem) async throws {
        switch item.id {
        case .movie(let movieId):
            let notificationIdentifier = String(movieId)
            await remove(notificationWith: notificationIdentifier)

            if case .toWatch = item.state {
                let webService = MovieWebService(requestManager: requestManager)
                let movie = try await webService.fetchMovie(with: movieId)
                if movie.details.release > Date.now {
                    try await schedule(notificationWith: notificationIdentifier, for: movie)
                }
            }
        }
    }

    private func remove(for item: WatchlistItem) async {
        switch item.id {
        case .movie(let movieId):
            let notificationIdentifier = String(movieId)
            await remove(notificationWith: notificationIdentifier)
        }
    }

    // MARK: Notifications

    private func requestAuthorization() async throws {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard case .notDetermined = settings.authorizationStatus else { return }
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
    }

    private func schedule(notificationWith identifier: String, for movie: Movie) async throws {
        try await requestAuthorization()

        let content = UNMutableNotificationContent()
        content.title = movie.details.title
        content.subtitle = "Is released!"

        let timeInterval = movie.details.release.timeIntervalSinceNow

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        let notificationCenter = UNUserNotificationCenter.current()
        try await notificationCenter.add(request)
    }

    private func remove(notificationWith identifier: String) async {
        let notificationCenter = UNUserNotificationCenter.current()
        let notifications = await notificationCenter.pendingNotificationRequests()
        if notifications.contains(where: { $0.identifier == identifier }) {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }
}
