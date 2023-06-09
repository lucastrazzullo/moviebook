//
//  WatchNextStorage.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import Foundation
import UIKit
import WidgetKit

public struct WatchNextItem: Codable {

    enum Error: Swift.Error {
        case unableToDecodeImage
    }

    enum CodingKeys: CodingKey {
        case title, image
    }

    public let title: String
    public let image: UIImage?

    public init(title: String, image: UIImage?) {
        self.title = title
        self.image = image
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let imageData = try container.decodeIfPresent(Data.self, forKey: .image) {
            guard let image = UIImage(data: imageData) else {
                throw Error.unableToDecodeImage
            }

            self.image = image
        } else {
            self.image = nil
        }

        self.title = try container.decode(String.self, forKey: .title)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        let imageData = image?.jpegData(compressionQuality: 1.0)
        try container.encode(imageData, forKey: .image)
        try container.encode(title, forKey: .title)
    }
}

public actor WatchNextStorage {

    private static let userDefaultsKey: String = "watch-next-key"
    private static let userDefaultsGroup: String = "group.it.lucastrazzullo.ios.moviebook.Shared"

    private let webService: MovieWebService

    public init(webService: MovieWebService) {
        self.webService = webService
    }

    public func set(items: [WatchlistItem]) async {
        WidgetCenter.shared.reloadAllTimelines()

        let identifiers = items.compactMap { item in
            if case .toWatch = item.state {
                return item.id
            } else {
                return nil
            }
        }

        let watchNextItems = await withTaskGroup(of: WatchNextItem?.self) { group in
            var result = [WatchNextItem]()
            result.reserveCapacity(identifiers.count)

            for identifier in identifiers {
                group.addTask {
                    return await self.loadItem(withWatchlistItentifier: identifier)
                }
            }

            for await item in group {
                if let item {
                    result.append(item)
                }
            }

            return result
        }

        store(items: watchNextItems)
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

    private func store(items: [WatchNextItem]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults(suiteName: Self.userDefaultsGroup)?.set(data, forKey: Self.userDefaultsKey)
        }
    }

    private func loadItem(withWatchlistItentifier identifier: WatchlistItemIdentifier) async -> WatchNextItem? {
        do {
            switch identifier {
            case .movie(let id):
                return try await self.loadItem(withMovieIdentifier: id)
            }
        } catch {
            return nil
        }
    }

    private func loadItem(withMovieIdentifier identifier: Movie.ID) async throws -> WatchNextItem? {
        let movie = try await self.webService.fetchMovie(with: identifier)
        if let posterUrl = movie.details.media.posterPreviewUrl {
            let image = try await ImageLoader().fetch(posterUrl)
            return WatchNextItem(title: movie.details.title, image: image)
        } else {
            return nil
        }
    }
}
