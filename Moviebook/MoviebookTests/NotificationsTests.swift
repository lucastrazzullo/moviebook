//
//  NotificationsTests.swift
//  MoviebookTests
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import XCTest
import Combine
import MoviebookCommon
import MoviebookTestSupport
import TheMovieDb

@testable import Moviebook

final class NotificationsTests: XCTestCase {

    private var mockServer: StubMockServer!
    private var requestLoader: RequestLoader!
    private var notificationCenter: MockUserNotificationCenter!
    private var notifications: Notifications!
    private var subscriptions: Set<AnyCancellable>!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockServer = StubMockServer()
        requestLoader = MockRequestLoader(server: mockServer)
        notificationCenter = MockUserNotificationCenter()
        notificationCenter.delegate = self
        notifications = Notifications(notificationCenter: notificationCenter)
        subscriptions = []
    }

    override func tearDownWithError() throws {
        subscriptions.forEach({ $0.cancel() })
        subscriptions = nil
        notifications = nil
        notificationCenter = nil
        requestLoader = nil
        try super.tearDownWithError()
    }

    // MARK: Tests

    func testScheduleNotifications_forNotReleasedMoviesOnly() async throws {

        // Setup

        let notReleasedMovies: [Movie] = [
            makeMovie(id: 0, releaseDate: .now.addingTimeInterval(1000000)),
            makeMovie(id: 1, releaseDate: .now.addingTimeInterval(2000000))
        ]
        let releasedMovies: [Movie] = [
            makeMovie(id: 2, releaseDate: .now.addingTimeInterval(-1000000)),
            makeMovie(id: 3, releaseDate: .now.addingTimeInterval(-2000000))
        ]

        let movies = notReleasedMovies + releasedMovies
        try addStubs(movies: movies)

        let toWatchItems = makeToWatchWatchlistItems(movieIdentifiers: movies.map(\.id))
        let watchlist = await Watchlist(items: toWatchItems)


        // Act

        await notifications.schedule(for: watchlist, requestLoader: requestLoader)


        // Assert

        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, notReleasedMovies.count)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)
        XCTAssertEqual(notificationCenter.pendingNotifications.count, notReleasedMovies.count)
    }

    func testScheduleNotifications_forToWatchMoviesOnly() async throws {

        // Setup

        let notReleasedMoviesToWatch: [Movie] = [
            makeMovie(id: 0, releaseDate: .now.addingTimeInterval(1000000)),
            makeMovie(id: 1, releaseDate: .now.addingTimeInterval(2000000))
        ]
        let notReleasedMoviesWatched: [Movie] = [
            makeMovie(id: 2, releaseDate: .now.addingTimeInterval(1000000)),
            makeMovie(id: 3, releaseDate: .now.addingTimeInterval(2000000))
        ]

        let movies = notReleasedMoviesToWatch + notReleasedMoviesWatched
        try addStubs(movies: movies)

        let toWatchItems = makeToWatchWatchlistItems(movieIdentifiers: notReleasedMoviesToWatch.map(\.id))
        let watchedItems = makeWatchedWatchlistItems(movieIdentifiers: notReleasedMoviesWatched.map(\.id))
        let watchlist = await Watchlist(items: toWatchItems + watchedItems)


        // Act

        await notifications.schedule(for: watchlist, requestLoader: requestLoader)


        // Assert

        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, notReleasedMoviesToWatch.count)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)
        XCTAssertEqual(notificationCenter.pendingNotifications.count, notReleasedMoviesToWatch.count)
    }

    func testScheduleNotifications_whenUpdatingSameMovieReleaseDate() async throws {

        // Setup

        var movie = makeMovie(id: 0, releaseDate: .now.addingTimeInterval(100000))
        try addStubs(movies: [movie])

        var items = makeToWatchWatchlistItems(movieIdentifiers: [movie.id])
        var watchlist = await Watchlist(items: items)

        // Act

        await notifications.schedule(for: watchlist, requestLoader: requestLoader)

        // Assert

        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, 1)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)
        XCTAssertEqual(notificationCenter.pendingNotifications.count, 1)

        // Update setup

        movie = makeMovie(id: 0, releaseDate: .now.addingTimeInterval(200000))
        try addStubs(movies: [movie])

        items = makeToWatchWatchlistItems(movieIdentifiers: [movie.id])
        watchlist = await Watchlist(items: items)

        // Act again

        await notifications.schedule(for: watchlist, requestLoader: requestLoader)

        // Assert again

        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, 2)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 1)
        XCTAssertEqual(notificationCenter.pendingNotifications.count, 1)
    }

    func testScheduleNotifications_whenAddingMoviesToWatchlist() async throws {

        // Setup

        let expectation = expectation(description: "watchlist update")
        expectation.expectedFulfillmentCount = 2

        let watchlist = await Watchlist(items: [])
        await watchlist.itemDidUpdateState
            .throttle(for: 1, scheduler: RunLoop.main, latest: true)
            .sink { _ in expectation.fulfill() }
            .store(in: &subscriptions)

        await notifications.schedule(for: watchlist, requestLoader: requestLoader)

        let movie1 = makeMovie(id: 0, releaseDate: .now.addingTimeInterval(100000))
        let movie2 = makeMovie(id: 1, releaseDate: .now.addingTimeInterval(100000))
        let movies = [movie1, movie2]
        try addStubs(movies: movies)

        // Act

        await watchlist.update(state: .toWatch(info: .init(date: .now)), forItemWith: .movie(id: movie1.id))
        await watchlist.update(state: .toWatch(info: .init(date: .now)), forItemWith: .movie(id: movie2.id))

        // Assert

        await fulfillment(of: [expectation])

        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, movies.count)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 0)
        XCTAssertEqual(notificationCenter.pendingNotifications.count, movies.count)
    }

    func testRemoveScheduledNotifications_whenSettingMovieToWatched() async throws {

        // Setup

        let expectation = expectation(description: "watchlist update")
        expectation.expectedFulfillmentCount = 1

        let movie1 = makeMovie(id: 0, releaseDate: .now.addingTimeInterval(100000))
        let movie2 = makeMovie(id: 1, releaseDate: .now.addingTimeInterval(100000))
        let movies = [movie1, movie2]
        try addStubs(movies: movies)

        let items = makeToWatchWatchlistItems(movieIdentifiers: movies.map(\.id))

        let watchlist = await Watchlist(items: items)
        await watchlist.itemDidUpdateState
            .throttle(for: 1, scheduler: RunLoop.main, latest: true)
            .sink { _ in expectation.fulfill() }
            .store(in: &subscriptions)

        await notifications.schedule(for: watchlist, requestLoader: requestLoader)

        // Act

        await watchlist.update(state: .watched(info: .init(toWatchInfo: .init(date: .now), date: .now)), forItemWith: .movie(id: movie1.id))

        // Assert

        await fulfillment(of: [expectation])

        XCTAssertEqual(notificationCenter.totalNumberOfScheduledNotifications, 2)
        XCTAssertEqual(notificationCenter.totalNumberOfRemovedNotifications, 1)
        XCTAssertEqual(notificationCenter.pendingNotifications.count, 1)
    }

    // MARK: Private helper methods

    private func addStubs(movies: [Movie]) throws {
        try movies.forEach { movie in
            let url = try TheMovieDbUrlFactory.movie(identifier: movie.id).makeUrl()
            let movie = TMDBMovieResponse(movie: movie)
            let stub = try MockStub(url: url, value: movie)
            mockServer.addStub(stub)
        }
    }

    // MARK: Private factory methods

    private func makeToWatchWatchlistItems(movieIdentifiers: [Movie.ID]) -> [WatchlistItem] {
        movieIdentifiers.map { movieId in
            WatchlistItem(id: .movie(id: movieId), state: .toWatch(info: .init(date: .now)))
        }
    }

    private func makeWatchedWatchlistItems(movieIdentifiers: [Movie.ID]) -> [WatchlistItem] {
        movieIdentifiers.map { movieId in
            WatchlistItem(id: .movie(id: movieId), state: .watched(info: .init(toWatchInfo: .init(date: .now), date: .now)))
        }
    }

    private func makeMovie(id: Movie.ID, releaseDate: Date) -> Movie {
        let imageUrl = URL(string: "https://image.tmdb.org/t/p/original/eKi8dIrr8voobbaGzDpe8w0PVbC.jpg")!
        return Movie(
            id: id,
            details: MovieDetails(
                id: id,
                title: "Title 1",
                release: releaseDate,
                localisedReleases: [:],
                runtime: nil,
                overview: nil,
                budget: nil,
                revenue: nil,
                rating: Rating(value: 1, quota: 1),
                media: MovieMedia(
                    posterUrl: imageUrl,
                    posterPreviewUrl: imageUrl,
                    posterThumbnailUrl: imageUrl,
                    backdropUrl: imageUrl,
                    backdropPreviewUrl: imageUrl,
                    videos: []
                )
            ),
            genres: [],
            keywords: [],
            cast: [],
            production: MovieProduction(companies: []),
            watch: WatchProviders(collections: [:])
        )
    }
}

extension NotificationsTests: NotificationsDelegate {

    func shouldRequestAuthorization(forMovieWith title: String) async -> Bool {
        return true
    }

    func shouldAuthorizeNotifications(forMovieWith title: String) {
    }
}

// MARK: Mock classes

private final class MockUserNotificationCenter: UserNotificationCenter {

    private(set) var pendingNotifications: [UNNotificationRequest] = []
    private(set) var totalNumberOfScheduledNotifications: Int = 0
    private(set) var totalNumberOfRemovedNotifications: Int = 0

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
        Task { @MainActor in
            pendingNotifications.append(request)
            totalNumberOfScheduledNotifications += 1
        }
    }

    func removePendingNotificationRequests(withIdentifiers: [String]) {
        let identifiers = Set(withIdentifiers)

        if let index = pendingNotifications.firstIndex(where: { identifiers.contains($0.identifier) }) {
            Task { @MainActor in
                pendingNotifications.remove(at: index)
                totalNumberOfRemovedNotifications += 1
            }
        }
    }
}
