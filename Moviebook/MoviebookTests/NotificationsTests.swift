//
//  NotificationsTests.swift
//  MoviebookTests
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import XCTest
import MoviebookCommon
import MoviebookTestSupport
@testable import Moviebook

final class NotificationsTests: XCTestCase {

    private var requestManager: RequestManager!
    private var notificationCenter: MockUserNotificationCenter!
    private var notifications: Notifications!

    override func setUpWithError() throws {
        try super.setUpWithError()
        requestManager = MockRequestManager()
        notificationCenter = MockUserNotificationCenter()
        notificationCenter.delegate = self

        notifications = Notifications(notificationCenter: notificationCenter)
    }

    override func tearDownWithError() throws {
        notifications = nil
        notificationCenter = nil
        requestManager = nil
        try super.tearDownWithError()
    }

    // MARK: Tests

    func testScheduleNotifications_forNotReleasedMoviesOnlt() async {
        let notReleasedMovieIdentifiers = makeNotReleasedMovieIdentifiers()
        let releasedMovieIdentifiers = makeReleasedMovieIdentifiers()
        let watchlist = await makeWatchlist(movieIdentifiers: notReleasedMovieIdentifiers + releasedMovieIdentifiers)

        await notifications.schedule(for: watchlist, requestManager: requestManager)
        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, notReleasedMovieIdentifiers.count)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)
    }

    func testScheduleNotifications_onlyOnce() async {
        let notReleasedMovieIdentifiers = makeNotReleasedMovieIdentifiers()
        let releasedMovieIdentifiers = makeReleasedMovieIdentifiers()
        let watchlist = await makeWatchlist(movieIdentifiers: notReleasedMovieIdentifiers + releasedMovieIdentifiers)

        await notifications.schedule(for: watchlist, requestManager: requestManager)
        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, notReleasedMovieIdentifiers.count)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)

        notificationCenter.cleanState()

        await notifications.schedule(for: watchlist, requestManager: requestManager)
        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, 0)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)
    }

    // MARK: Private factory methods

    private func makeWatchlist(movieIdentifiers: [Movie.ID]) async -> Watchlist {
        let items = makeToWatchWatchlistItems(movieIdentifiers: movieIdentifiers)
        return await Watchlist(items: items)
    }

    private func makeToWatchWatchlistItems(movieIdentifiers: [Movie.ID]) -> [WatchlistItem] {
        movieIdentifiers.map { movieId in
            WatchlistItem(id: .movie(id: movieId), state: .toWatch(info: .init(date: .now)))
        }
    }

    private func makeNotReleasedMovieIdentifiers() -> [Movie.ID] {
        return [353081, 616037]
    }

    private func makeReleasedMovieIdentifiers() -> [Movie.ID] {
        return [954]
    }
}

extension NotificationsTests: NotificationsDelegate {

    func shouldRequestAuthorization() async -> Bool {
        return true
    }

    func shouldAuthorizeNotifications() {
    }
}

private final class MockUserNotificationCenter: UserNotificationCenter {

    private var pendingNotifications: [UNNotificationRequest] = []
    private(set) var totalNumberOfScheduledNotifications: Int = 0
    private(set) var totalNumberOfRemovedNotifications: Int = 0

    func cleanState() {
        totalNumberOfRemovedNotifications = 0
        totalNumberOfScheduledNotifications = 0
    }

    // MARK: UserNotificationCenter

    var delegate: UNUserNotificationCenterDelegate?

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        return true
    }

    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        return .authorized
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return pendingNotifications
    }

    func add(_ request: UNNotificationRequest) async throws {
        pendingNotifications.append(request)
        totalNumberOfScheduledNotifications += 1
    }

    func removePendingNotificationRequests(withIdentifiers: [String]) {
        let identifiers = Set(withIdentifiers)

        if let index = pendingNotifications.firstIndex(where: { identifiers.contains($0.identifier) }) {
            pendingNotifications.remove(at: index)
            totalNumberOfRemovedNotifications += 1
        }
    }
}
