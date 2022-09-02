//
//  MockRequestManager.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

#if DEBUG
final class MockRequestManager: RequestManager {

    private let server: MockServer = MockServer()

    func request(from url: URL) async throws -> Data {
        return try server.data(from: url)
    }
}
#endif
