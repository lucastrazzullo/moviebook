//
//  RequestLoader.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

public protocol RequestLoader: AnyObject {
    func request(from url: URL) async throws -> Data
}

public actor DefaultRequestLoader: RequestLoader {

    private enum LoaderStatus {
        case inProgress(Task<Data, Error>)
        case fetched(CacheEntry<Data>)
    }

    // MARK: Private properties

    private let responseLifetime: TimeInterval = 12*60*60

    private let persistentCache: PersistentCache
    private var requests: [URLRequest: LoaderStatus]

    // MARK: Object life cycle

    public init() {
        self.persistentCache = PersistentCache()
        self.requests = [:]
    }

    // MARK: Public methods

    public func request(from url: URL) async throws -> Data {
        let urlRequest = URLRequest(url: url)

        do {
            if let status = requests[urlRequest] {
                switch status {
                case .fetched(let cacheEntry) where !cacheEntry.isExpired:
                    return cacheEntry.content
                case .inProgress(let task):
                    return try await task.value
                default:
                    break
                }
            }

            if let cachedEntry: CacheEntry<Data> = try? persistentCache.getCached(for: urlRequest) {
                requests[urlRequest] = .fetched(cachedEntry)
                return cachedEntry.content
            }

            let sessionConfiguguration = URLSessionConfiguration.default
            sessionConfiguguration.timeoutIntervalForRequest = 10.0
            sessionConfiguguration.timeoutIntervalForResource = 20.0
            let session = URLSession(configuration: sessionConfiguguration)

            let task: Task<Data, Error> = Task {
                let (data, _) = try await session.data(from: url)
                let cacheEntry = CacheEntry(content: data, lifeTime: responseLifetime)
                try? persistentCache.cache(cacheEntry, for: urlRequest)
                requests[urlRequest] = .fetched(cacheEntry)
                return data
            }

            requests[urlRequest] = .inProgress(task)
            return try await task.value

        } catch {
            requests[urlRequest] = nil
            throw error
        }
    }
}
