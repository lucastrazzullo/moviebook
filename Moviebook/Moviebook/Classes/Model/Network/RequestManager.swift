//
//  RequestManager.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

protocol RequestManager {
    func request(from url: URL) async throws -> Data
}

final class DefaultRequestManager: RequestManager {

    enum Logging {
        case disabled
        case enabled
    }

    private let logging: Logging

    init(logging: Logging) {
        self.logging = logging
    }

    // MARK: Internal methods

    func request(from url: URL) async throws -> Data {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)

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
        print("Request")
        print(url.description)
        print("-------")

        if let response = data {
            print("Response")
            print(String(describing: String(data: response, encoding: .utf8)))
            print("-------")
        }

        if let error = error {
            print("Error")
            print(error)
            print("-------")
        }

        print("-------")
    }
}
