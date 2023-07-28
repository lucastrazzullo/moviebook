//
//  CacheEntryTests.swift
//  MoviebookCommonTests
//
//  Created by Luca Strazzullo on 22/07/2023.
//

import XCTest
@testable import MoviebookCommon

final class CacheEntryTests: XCTestCase {

    func testResponseLifecycle() {
        let lifeTime: TimeInterval = 24*60*60
        var createdDate = Date.now.addingTimeInterval(-24*60*60)
        var response = CacheEntry(content: Data(), createdDate: createdDate, lifeTime: lifeTime)
        XCTAssertTrue(response.isExpired)

        createdDate = Date.now.addingTimeInterval(-25*60*60)
        response = CacheEntry(content: Data(), createdDate: createdDate, lifeTime: lifeTime)
        XCTAssertTrue(response.isExpired)

        createdDate = Date.now.addingTimeInterval(-23*60*60)
        response = CacheEntry(content: Data(), createdDate: createdDate, lifeTime: lifeTime)
        XCTAssertFalse(response.isExpired)
    }
}
