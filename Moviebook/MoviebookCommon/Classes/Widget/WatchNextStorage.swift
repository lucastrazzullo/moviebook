//
//  WatchNextStorage.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import Foundation
import UIKit
import WidgetKit

public struct WatchNextItem: Codable, Equatable {

    enum Error: Swift.Error {
        case unableToDecodeImage
    }

    enum CodingKeys: CodingKey {
        case title, image, deeplink
    }

    public let title: String?
    public let image: UIImage?
    public let deeplink: Deeplink?

    public init(title: String?, image: UIImage?, deeplink: Deeplink?) {
        self.title = title
        self.image = image
        self.deeplink = deeplink
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let deeplinkUrl = try container.decodeIfPresent(URL.self, forKey: .deeplink) {
            self.deeplink = Deeplink(rawValue: deeplinkUrl)
        } else {
            self.deeplink = nil
        }

        if let imageData = try container.decodeIfPresent(Data.self, forKey: .image) {
            guard let image = UIImage(data: imageData) else {
                throw Error.unableToDecodeImage
            }

            self.image = image
        } else {
            self.image = nil
        }

        self.title = try container.decodeIfPresent(String.self, forKey: .title)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let deeplinkUrl = deeplink?.rawValue
        try container.encode(deeplinkUrl, forKey: .deeplink)
        let imageData = image?.jpegData(compressionQuality: 1.0)
        try container.encode(imageData, forKey: .image)
        try container.encode(title, forKey: .title)
    }
}

public actor WatchNextStorage {

    private static let storedFileName: String = "watch-next-items.json"
    private static let appGroupIdentifier: String = "group.it.lucastrazzullo.ios.moviebook.Shared"

    private let webService: MovieWebService

    public init(webService: MovieWebService) {
        self.webService = webService
    }

    public func set(items: [WatchlistItem]) async throws {
        var identifiers = items.compactMap { item in
            if case .toWatch = item.state {
                return item.id
            } else {
                return nil
            }
        }

        if identifiers.isEmpty, let nowPlayingMovies = try? await webService.fetchMovies(discoverSection: .nowPlaying, genres: [], page: nil) {
            identifiers = nowPlayingMovies.results.map { movie in .movie(id: movie.id) }
        }

        let watchNextItems = try await withThrowingTaskGroup(of: (identifier: WatchlistItemIdentifier, item: WatchNextItem)?.self) { group in
            var result = [WatchlistItemIdentifier: WatchNextItem]()
            result.reserveCapacity(identifiers.count)

            for identifier in identifiers {
                group.addTask {
                    return try? await self.loadItem(withWatchlistItentifier: identifier)
                }
            }

            for try await response in group {
                if let response {
                    result[response.identifier] = response.item
                }
            }

            var items = [WatchNextItem]()
            items.reserveCapacity(identifiers.count)

            for identifier in identifiers {
                if let item = result[identifier] {
                    items.append(item)
                }
            }

            return items
        }

        if let data = try? JSONEncoder().encode(watchNextItems) {
            Self.storeItemsData(data)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func getItems() -> [WatchNextItem] {
        guard let data = Self.getStoredItemsData() else {
            return []
        }
        guard let items = try? JSONDecoder().decode([WatchNextItem].self, from: data) else {
            return []
        }
        return items
    }

    // MARK: Private helper methods

    private func loadItem(withWatchlistItentifier identifier: WatchlistItemIdentifier) async throws -> (identifier: WatchlistItemIdentifier, item: WatchNextItem) {
        switch identifier {
        case .movie(let id):
            return (identifier: identifier, item: try await self.loadItem(withMovieIdentifier: id))
        }
    }

    private func loadItem(withMovieIdentifier identifier: Movie.ID) async throws -> WatchNextItem {
        let movie = try await self.webService.fetchMovie(with: identifier)
        let posterUrl = movie.details.media.posterThumbnailUrl
        let image = try await ImageLoader().fetch(posterUrl)
        let deeplink = Deeplink.movie(identifier: movie.id)
        return WatchNextItem(title: movie.details.title, image: image, deeplink: deeplink)
    }

    // MARK: File manager

    private static func getStoredItemsData() -> Data? {
        guard let url = getDocumentsDirectory()?.appendingPathComponent(Self.storedFileName, isDirectory: false) else {
            return nil
        }

        return FileManager.default.contents(atPath: url.path)
    }

    private static func storeItemsData(_ data: Data) {
        guard let url = getDocumentsDirectory()?.appendingPathComponent(Self.storedFileName, isDirectory: false) else {
            return
        }

        if FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }

        FileManager.default.createFile(atPath: url.path, contents: data, attributes: nil)
    }

    private static func getDocumentsDirectory() -> URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier)
    }
}
