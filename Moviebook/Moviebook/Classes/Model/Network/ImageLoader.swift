//
//  ImageLoader.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/06/2023.
//

import Foundation
import SwiftUI
import UIKit

actor ImageLoader {

    private enum LoaderStatus {
        case inProgress(Task<UIImage, Error>)
        case fetched(UIImage)
    }

    private let cache: NSCache = NSCache<AnyObject, AnyObject>()
    private var images: [URLRequest: LoaderStatus] = [:]

    func fetch(_ url: URL) async throws -> UIImage {
        let urlRequest = URLRequest(url: url)

        if let status = images[urlRequest] {
            switch status {
            case .fetched(let image):
                return image
            case .inProgress(let task):
                return try await task.value
            }
        }

        if let image = self.getCachedImage(for: urlRequest) {
            images[urlRequest] = .fetched(image)
            return image
        }

        let task: Task<UIImage, Error> = Task {
            let (imageData, _) = try await URLSession.shared.data(for: urlRequest)
            let image = UIImage(data: imageData)!
            self.cacheImage(image, for: urlRequest)
            return image
        }

        images[urlRequest] = .inProgress(task)

        let image = try await task.value

        images[urlRequest] = .fetched(image)

        return image
    }

    private func cacheImage(_ image: UIImage, for urlRequest: URLRequest) {
        guard let key = urlRequest.url?.absoluteString else { return }
        cache.setObject(image, forKey: NSString(string: key))
    }

    private func getCachedImage(for urlRequest: URLRequest) -> UIImage? {
        guard let key = urlRequest.url?.absoluteString else { return nil }
        return cache.object(forKey: NSString(string: key)) as? UIImage
    }
}
