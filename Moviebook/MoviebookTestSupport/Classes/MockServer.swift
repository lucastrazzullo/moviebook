//
//  MockServer.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

final class MockServer {

    enum Error: Swift.Error {
        case cannotFindMocksBundle
        case cannotFindMocksFile
    }

    func data(from url: URL) throws -> Data {
        guard let bundle = Bundle(identifier: "it.lucastrazzullo.ios.MoviebookTestSupport") else {
            throw Error.cannotFindMocksBundle
        }

        guard let url = bundle.url(forResource: "Mocks\(url.path)", withExtension: "json") else {
            throw Error.cannotFindMocksFile
        }

        return try Data(contentsOf: url)
    }
}
