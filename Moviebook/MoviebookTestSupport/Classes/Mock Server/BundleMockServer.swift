//
//  BundleMockServer.swift
//  MoviebookTestSupport
//
//  Created by Luca Strazzullo on 22/06/2023.
//

import Foundation

public final class BundleMockServer: MockServer {

    enum Error: Swift.Error {
        case cannotFindMocksBundle
        case cannotFindMocksFile
    }

    private let bundleIdentifier: String
    private let resourceName: String

    public init(bundleIdentifier: String, resourceName: String) {
        self.bundleIdentifier = bundleIdentifier
        self.resourceName = resourceName
    }

    public func data(from url: URL) throws -> Data {
        guard let bundle = Bundle(identifier: bundleIdentifier) else {
            throw Error.cannotFindMocksBundle
        }

        guard let url = bundle.url(forResource: "Mocks\(url.path)", withExtension: "json") else {
            throw Error.cannotFindMocksFile
        }

        return try Data(contentsOf: url)
    }
}
