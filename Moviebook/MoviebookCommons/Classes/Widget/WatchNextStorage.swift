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

    enum Error: Swift.Error {
        case unableToLoadItem
    }

    private static let userDefaultsKey: String = "watch-next-key"
    private static let userDefaultsGroup: String = "group.it.lucastrazzullo.ios.moviebook.Shared"

    private let webService: MovieWebService

    public init(webService: MovieWebService) {
        self.webService = webService
    }

    public func set(items: [WatchlistItem]) async {
        let identifiers = items.compactMap { item in
            if case .toWatch = item.state {
                return item.id
            } else {
                return nil
            }
        }

        let watchNextItems = await withTaskGroup(of: (identifier: WatchlistItemIdentifier, item: WatchNextItem)?.self) { group in
            var result = [WatchlistItemIdentifier: WatchNextItem]()
            result.reserveCapacity(identifiers.count)

            for identifier in identifiers {
                group.addTask {
                    return try? await self.loadItem(withWatchlistItentifier: identifier)
                }
            }

            for await response in group {
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
            UserDefaults(suiteName: Self.userDefaultsGroup)?.set(data, forKey: Self.userDefaultsKey)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    public static func getItems() -> [WatchNextItem] {
        if let data = UserDefaults(suiteName: Self.userDefaultsGroup)?.data(forKey: Self.userDefaultsKey),
           let items = try? JSONDecoder().decode([WatchNextItem].self, from: data) {
            return items
        } else {
            return []
        }
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
        if let posterUrl = movie.details.media.posterPreviewUrl {
            let image = try await ImageLoader().fetch(posterUrl)
            let deeplink = Deeplink.movie(identifier: movie.id)
            return WatchNextItem(title: movie.details.title, image: image, deeplink: deeplink)
        } else {
            throw Error.unableToLoadItem
        }
    }
}
