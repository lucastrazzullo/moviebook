//
//  PersistentCache.swift
//  MoviebookCommon
//
//  Created by Luca Strazzullo on 26/07/2023.
//

import Foundation

final class CacheEntry<Content: Codable>: Codable {

    let content: Content
    let createdDate: Date
    let lifeTime: TimeInterval

    var isExpired: Bool {
        createdDate + lifeTime < Date.now
    }

    init(content: Content, createdDate: Date = .now, lifeTime: TimeInterval = 24*60*60) {
        self.content = content
        self.createdDate = createdDate
        self.lifeTime = lifeTime
    }
}

struct PersistentCache {

    func cache<Content: Codable>(_ entry: CacheEntry<Content>, for urlRequest: URLRequest) throws {
        guard let fileName = fileName(for: urlRequest) else { return }
        let data = try JSONEncoder().encode(entry)
        try data.write(to: fileName)
    }

    func getCached<Content: Codable>(for urlRequest: URLRequest) throws -> CacheEntry<Content>? {
        guard let url = fileName(for: urlRequest) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return nil
        }

        let data = try Data(contentsOf: url)
        let entry = try JSONDecoder().decode(CacheEntry<Content>.self, from: data)
        guard !entry.isExpired else {
            try cleanCache(for: urlRequest)
            return nil
        }

        return entry
    }

    private func cleanCache(for urlRequest: URLRequest) throws {
        guard let url = fileName(for: urlRequest) else {
            assertionFailure("Unable to generate a local path for \(urlRequest)")
            return
        }

        try FileManager.default.removeItem(at: url)
    }

    private func fileName(for urlRequest: URLRequest) -> URL? {
        guard let fileName = urlRequest.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                  return nil
              }

        return applicationSupport.appendingPathComponent(fileName.replacingOccurrences(of: "/", with: "-"))
    }
}
