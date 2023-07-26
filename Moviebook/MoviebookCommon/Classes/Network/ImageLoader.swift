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
        case fetched(CacheEntry)
    }

    private var images: [URLRequest: LoaderStatus]

    public init() {
        self.images = [:]
    }

    public func fetch(_ url: URL) async throws -> UIImage {
        let urlRequest = URLRequest(url: url)

        do {
            if let status = images[urlRequest] {
                switch status {
                case .fetched(let image) where !image.isExpired:
                    return UIImage(data: image.data)!
                case .inProgress(let task):
                    return try await task.value
                default:
                    break
                }
            }

            if let cachedImage = try? LoaderCache.getCached(for: urlRequest), !cachedImage.isExpired {
                images[urlRequest] = .fetched(cachedImage)
                return UIImage(data: cachedImage.data)!
            }

            let task: Task<UIImage, Error> = Task {
                let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
                let entry = CacheEntry(data: imageData)
                try? LoaderCache.cache(entry, for: urlRequest)
                images[urlRequest] = .fetched(entry)
                return UIImage(data: imageData)!
            }

            images[urlRequest] = .inProgress(task)
            return try await task.value

        } catch {
            images[urlRequest] = nil
            throw error
        }
    }
}
