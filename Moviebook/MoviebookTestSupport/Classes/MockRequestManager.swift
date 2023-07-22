//
//  MockRequestLoader.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import MoviebookCommon

public final class MockRequestLoader: RequestLoader {

    private let server: MockServer

    public init(server: MockServer) {
        self.server = server
    }

    public func request(from url: URL) async throws -> Data {
        return try server.data(from: url)
    }
}
