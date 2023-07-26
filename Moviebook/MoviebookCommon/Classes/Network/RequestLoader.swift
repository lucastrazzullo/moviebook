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
        case fetched(CacheEntry)
    }

    // MARK: Private properties

    private var requests: [URLRequest: LoaderStatus]

    // MARK: Object life cycle

    public init() {
        self.requests = [:]
    }

    // MARK: Internal methods

    public func request(from url: URL) async throws -> Data {
        let urlRequest = URLRequest(url: url)

        do {
            if let status = requests[urlRequest] {
                switch status {
                case .fetched(let response) where !response.isExpired:
                    return response.data
                case .inProgress(let task):
                    return try await task.value
                default:
                    break
                }
            }

            if let cachedResponse = try? LoaderCache.getCached(for: urlRequest), !cachedResponse.isExpired {
                requests[urlRequest] = .fetched(cachedResponse)
                return cachedResponse.data
            }

            let sessionConfiguguration = URLSessionConfiguration.default
            sessionConfiguguration.timeoutIntervalForRequest = 10.0
            sessionConfiguguration.timeoutIntervalForResource = 20.0
            let session = URLSession(configuration: sessionConfiguguration)

            let task: Task<Data, Error> = Task {
                let (data, _) = try await session.data(from: url)
                let entry = CacheEntry(data: data)
                try? LoaderCache.cache(entry, for: urlRequest)
                requests[urlRequest] = .fetched(entry)
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
