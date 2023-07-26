//
//  LoaderCache.swift
//  MoviebookCommon
//
//  Created by Luca Strazzullo on 26/07/2023.
//

import Foundation

final class CacheEntry: Codable {

    private static let lifeTime: TimeInterval = 24 * 60 * 60

    let data: Data
    let createdDate: Date

    var isExpired: Bool {
        createdDate + Self.lifeTime < Date.now
    }

    init(data: Data) {
        self.data = data
        self.createdDate = Date.now
    }

    init(data: Data, createdDate: Date) {
        self.data = data
        self.createdDate = createdDate
    }
}

enum LoaderCache {

    static func cache(_ object: CacheEntry, for urlRequest: URLRequest) throws {
        guard let fileName = fileName(for: urlRequest) else { return }
        let data = try JSONEncoder().encode(object)
        try data.write(to: fileName)
    }

    static func getCached(for urlRequest: URLRequest) throws -> CacheEntry? {
        guard let url = fileName(for: urlRequest) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return nil
        }

        let data = try Data(contentsOf: url)
        let response = try JSONDecoder().decode(CacheEntry.self, from: data)
        return response
    }

    private static func fileName(for urlRequest: URLRequest) -> URL? {
        guard let fileName = urlRequest.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                  return nil
              }

        return applicationSupport.appendingPathComponent(fileName.replacingOccurrences(of: "/", with: "-"))
    }
}
