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
        let (data, _) = try await URLSession.shared.data(from: url)

        if logging == .enabled {
            log(request: url, response: data)
        }

        return data
    }

    // MARK: Private logging methods

    private func log(request url: URL, response data: Data) {
        print("Request")
        print(url.description)
        print("-------")
        print("Response")
        print(String(describing: String(data: data, encoding: .utf8)))
        print("-------")
        print("-------")
    }
}
