//
//  ImageLoader.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/06/2023.
//

import Foundation
import SwiftUI
import UIKit

public actor ImageLoader {

    private enum LoaderStatus {
        case inProgress(Task<UIImage, Error>)
        case fetched(CacheEntry<UIImageContainer>)
    }

    // MARK: Private properties

    private let imageLifetime: TimeInterval = 24*60*60

    private let persistentCache: PersistentCache
    private var images: [URLRequest: LoaderStatus]

    // MARK: Object life cycle

    public init() {
        self.persistentCache = PersistentCache()
        self.images = [:]
    }

    // MARK: Public methods

    public func fetch(_ url: URL) async throws -> UIImage {
        let urlRequest = URLRequest(url: url)

        do {
            if let status = images[urlRequest] {
                switch status {
                case .fetched(let cacheEntry) where !cacheEntry.isExpired:
                    return cacheEntry.content.image
                case .inProgress(let task):
                    return try await task.value
                default:
                    break
                }
            }

            if let cachedEntry: CacheEntry<UIImageContainer> = try? await persistentCache.getCached(for: urlRequest) {
                images[urlRequest] = .fetched(cachedEntry)
                return cachedEntry.content.image
            }

            let task: Task<UIImage, Error> = Task {
                let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
                let image = UIImage(data: imageData)!
                let imageContainer = UIImageContainer(image: image)
                let entry = CacheEntry(content: imageContainer, lifeTime: imageLifetime)
                try? await persistentCache.cache(entry, for: urlRequest)
                images[urlRequest] = .fetched(entry)
                return image
            }

            images[urlRequest] = .inProgress(task)
            return try await task.value

        } catch {
            images[urlRequest] = nil
            throw error
        }
    }
}

private struct UIImageContainer: Codable {

    enum CodingKeys: CodingKey {
        case data
    }

    let image: UIImage

    init(image: UIImage) {
        self.image = image
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.decode(Data.self, forKey: .data)
        self.image = UIImage(data: data)!
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let data = image.pngData()
        try container.encode(data, forKey: .data)
    }
}
