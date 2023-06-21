//
//  MockRequestManager.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import MoviebookCommon

public final class MockRequestManager: RequestManager {

    private let server: MockServer

    public init() {
        self.server = MockServer()
    }

    public func request(from url: URL) async throws -> Data {
        return try server.data(from: url)
    }
}
