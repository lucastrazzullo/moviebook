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
        var createdDate = Date.now.addingTimeInterval(-24*60*60)
        var response = CacheEntry(data: Data(), createdDate: createdDate)
        XCTAssertTrue(response.isExpired)

        createdDate = Date.now.addingTimeInterval(-25*60*60)
        response = CacheEntry(data: Data(), createdDate: createdDate)
        XCTAssertTrue(response.isExpired)

        createdDate = Date.now.addingTimeInterval(-23*60*60)
        response = CacheEntry(data: Data(), createdDate: createdDate)
        XCTAssertFalse(response.isExpired)
    }
}
