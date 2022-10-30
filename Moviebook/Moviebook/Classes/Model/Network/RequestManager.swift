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

    static let shared: RequestManager = DefaultRequestManager()

    private init() {}

    func request(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
}
