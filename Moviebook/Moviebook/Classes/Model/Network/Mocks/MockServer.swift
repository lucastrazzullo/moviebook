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

    // MARK: Helper methods

    static func movie(with identifier: Movie.ID) -> Movie {
        let data = try! MockServer().data(from: MovieWebService.URLFactory.makeMovieUrl(movieIdentifier: identifier))
        let movie = try! JSONDecoder().decode(Movie.self, from: data)
        return movie
    }
}
#endif
