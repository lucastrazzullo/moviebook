//
//  MockServer.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

#if DEBUG
final class MockServer {

    enum Error: Swift.Error {
        case cannotFindMocksBundle
    }

    func data(from url: URL) throws -> Data {
        guard let url = Bundle.main.url(forResource: "Mocks\(url.path)", withExtension: "json") else {
            throw Error.cannotFindMocksBundle
        }

        return try Data(contentsOf: url)
    }
}
#endif
