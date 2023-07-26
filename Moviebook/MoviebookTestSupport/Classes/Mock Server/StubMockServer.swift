//
//  StubMockServer.swift
//  MoviebookTestSupport
//
//  Created by Luca Strazzullo on 22/06/2023.
//

import Foundation
import MoviebookCommon

public final class StubMockServer: MockServer {

    enum Error: Swift.Error {
        case cannotFindStub
    }

    private var stubs: [MockStub]

    // MARK: Object life cycle

    public init(stubs: [MockStub] = []) {
        self.stubs = stubs
    }

    // MARK: Public methods

    public func addStub(_ stub: MockStub) {
        if let index = stubs.firstIndex(where: { $0.url == stub.url }) {
            stubs.remove(at: index)
        }
        self.stubs.append(stub)
    }

    public func data(from url: URL) throws -> Data {
        guard let stub = stubs.first(where: { $0.url == url }) else {
            throw Error.cannotFindStub
        }

        return try JSONEncoder().encode(stub.value)
    }
}

public struct MockStub {

    let url: URL
    let value: any Encodable

    public init(url: URL, value: any Encodable) throws {
        self.url = url
        self.value = value
    }
}

protocol StubUrlBuilder {
    func build() -> URL
}
