//
//  RequestManager.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

public protocol RequestManager: AnyObject {
    func request(from url: URL) async throws -> Data
}

public actor DefaultRequestManager: RequestManager {

    public enum Logging {
        case disabled
        case enabled
    }

    private let logging: Logging

    public init(logging: Logging) {
        self.logging = logging
    }

    // MARK: Internal methods

    public func request(from url: URL) async throws -> Data {
        do {
            if logging == .enabled {
                log(request: url, response: nil, error: nil)
            }

            let sessionConfiguguration = URLSessionConfiguration.default
            sessionConfiguguration.timeoutIntervalForRequest = 10.0
            sessionConfiguguration.timeoutIntervalForResource = 20.0

            let session = URLSession(configuration: sessionConfiguguration)
            let (data, _) = try await session.data(from: url)

            if logging == .enabled {
                log(request: url, response: data, error: nil)
            }

            return data
        } catch {
            if logging == .enabled {
                log(request: url, response: nil, error: error)
            }

            throw error
        }
    }

    // MARK: Private logging methods

    private func log(request url: URL, response data: Data?, error: Error?) {
        if data == nil && error == nil {
            print("[REQUEST MANAGER] Request started")
            print("[REQUEST MANAGER]", url.description)
            print("[REQUEST MANAGER] -------")
        }

        if let response = data {
            print("[REQUEST MANAGER] Response")
            print("[REQUEST MANAGER] from request:", url.description)
            print("[REQUEST MANAGER]", String(describing: String(data: response, encoding: .utf8)))
            print("[REQUEST MANAGER] -------")
        }

        if let error = error {
            print("[REQUEST MANAGER] Error")
            print("[REQUEST MANAGER] for request:", url.description)
            print("[REQUEST MANAGER]", error)
            print("[REQUEST MANAGER] -------")
        }

        print("[REQUEST MANAGER] -------")
    }
}
