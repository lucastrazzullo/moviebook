//
//  Notifications.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 19/06/2023.
//

import Foundation
import Combine
import UserNotifications
import MoviebookCommon

protocol NotificationsDelegate: AnyObject, UNUserNotificationCenterDelegate {
    func shouldRequestAuthorization() async -> Bool
    func shouldAuthorizeNotifications()
}

// MARK: Notification center

protocol UserNotificationCenter: AnyObject {
    var delegate: UNUserNotificationCenterDelegate? { get set }

    @discardableResult
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func getAuthorizationStatus() async -> UNAuthorizationStatus

    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers: [String])
}

extension UNUserNotificationCenter: UserNotificationCenter {

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
}

// MARK: Notifications

final class Notifications {

    enum Error: Swift.Error {
        case notificationsNotAuthorized
    }

    weak var delegate: NotificationsDelegate? {
        didSet {
            notificationCenter.delegate = delegate
        }
    }

    private let notificationCenter: UserNotificationCenter
    private var subscriptions: Set<AnyCancellable> = []

    init(notificationCenter: UserNotificationCenter = UNUserNotificationCenter.current()) {
        self.notificationCenter = notificationCenter
    }

    // MARK: Internal methods

    func schedule(for watchlist: Watchlist, requestManager: RequestManager) async {
        await withThrowingTaskGroup(of: Void.self) { group in
            let items = await watchlist.items
            for item in items {
                group.addTask {
                    try await self.schedule(for: item, requestManager: requestManager)
                }
            }
        }

        await watchlist.itemDidUpdateState
            .sink { item in Task { try await self.schedule(for: item, requestManager: requestManager) }}
            .store(in: &subscriptions)

        await watchlist.itemWasRemoved
            .sink { item in Task { await self.remove(for: item) }}
            .store(in: &subscriptions)
    }

    // MARK: Private scheduling methods

    private func schedule(for item: WatchlistItem, requestManager: RequestManager) async throws {
        switch item.id {
        case .movie(let movieId):
            let notificationIdentifier = String(movieId)
            if case .toWatch = item.state {
                let webService = MovieWebService(requestManager: requestManager)
                let movie = try await webService.fetchMovie(with: movieId)
                try await scheduleIfNeeded(notificationWith: notificationIdentifier, for: movie)
            } else {
                await remove(notificationWith: notificationIdentifier)
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

    private func scheduleIfNeeded(notificationWith identifier: String, for movie: Movie) async throws {
        let notifications = await notificationCenter.pendingNotificationRequests()

        if let scheduledNotification = notifications.first(where: { $0.identifier == identifier }) {
            if let trigger = scheduledNotification.trigger as? UNCalendarNotificationTrigger,
               let triggerDate = trigger.nextTriggerDate(), triggerDate != movie.details.release {
                await remove(notificationWith: identifier)

                if movie.details.release > Date.now {
                    try await schedule(notificationWith: identifier, for: movie)
                }
            }
        } else if movie.details.release > Date.now {
            try await schedule(notificationWith: identifier, for: movie)
        }
    }

    private func schedule(notificationWith identifier: String, for movie: Movie) async throws {
        try await requestAuthorization()

        let content = UNMutableNotificationContent()
        content.title = movie.details.title
        content.subtitle = "Is released!"
        content.categoryIdentifier = Deeplink.movie(identifier: movie.id).rawValue.absoluteString

        let dateComponents = Calendar.current.dateComponents(Set(arrayLiteral: Calendar.Component.year, Calendar.Component.month, Calendar.Component.day), from: movie.details.release)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await notificationCenter.add(request)
    }

    private func remove(notificationWith identifier: String) async {
        let notifications = await notificationCenter.pendingNotificationRequests()
        if notifications.contains(where: { $0.identifier == identifier }) {
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    }

    private func requestAuthorization() async throws {
        let status = await notificationCenter.getAuthorizationStatus()

        switch status {
        case .authorized:
            return
        case .notDetermined:
            if let shouldRequestAuthorization = await delegate?.shouldRequestAuthorization(), shouldRequestAuthorization {
                try await notificationCenter.requestAuthorization(options: [.alert])
            } else {
                throw Error.notificationsNotAuthorized
            }
        case .denied:
            delegate?.shouldAuthorizeNotifications()
            throw Error.notificationsNotAuthorized
        default:
            throw Error.notificationsNotAuthorized
        }
    }
}
