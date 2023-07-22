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

    final class Response {

        private let lifeTime: TimeInterval = 24 * 60 * 60

        let data: Data
        let createdDate: Date

        var isExpired: Bool {
            createdDate + lifeTime < Date.now
        }

        init(data: Data) {
            self.data = data
            self.createdDate = Date.now
        }

        init(data: Data, createdDate: Date) {
            self.data = data
            self.createdDate = createdDate
        }
    }

    private enum LoaderStatus {
        case inProgress(Task<Data, Error>)
        case fetched(Response)
    }

    // MARK: Private properties

    private var requests: [URLRequest: LoaderStatus]
    private let cache: NSCache<AnyObject, AnyObject>

    // MARK: Object life cycle

    public init() {
        self.requests = [:]
        self.cache = NSCache<AnyObject, AnyObject>()
    }

    // MARK: Internal methods

    public func request(from url: URL) async throws -> Data {
        do {
            let urlRequest = URLRequest(url: url)

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

            if let cachedResponse = self.getCachedResponse(for: urlRequest), !cachedResponse.isExpired {
                requests[urlRequest] = .fetched(cachedResponse)
                return cachedResponse.data
            }

            let sessionConfiguguration = URLSessionConfiguration.default
            sessionConfiguguration.timeoutIntervalForRequest = 10.0
            sessionConfiguguration.timeoutIntervalForResource = 20.0
            let session = URLSession(configuration: sessionConfiguguration)

            let task: Task<Data, Error> = Task {
                let (data, _) = try await session.data(from: url)
                let response = Response(data: data)
                self.cacheResponse(response, for: urlRequest)
                return data
            }

            requests[urlRequest] = .inProgress(task)

            let data = try await task.value
            let response = Response(data: data)
            requests[urlRequest] = .fetched(response)

            return data
        } catch {
            throw error
        }
    }

    private func cacheResponse(_ response: Response, for urlRequest: URLRequest) {
        guard let key = urlRequest.url?.absoluteString else { return }
        cache.setObject(response, forKey: NSString(string: key))
    }

    private func getCachedResponse(for urlRequest: URLRequest) -> Response? {
        guard let key = urlRequest.url?.absoluteString else { return nil }
        return cache.object(forKey: NSString(string: key)) as? Response
    }
}
