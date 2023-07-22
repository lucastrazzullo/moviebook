//
//  DefaultRequestLoaderTests.swift
//  MoviebookCommonTests
//
//  Created by Luca Strazzullo on 22/07/2023.
//

import XCTest
@testable import MoviebookCommon

final class DefaultRequestLoaderTests: XCTestCase {

    func testResponseLifecycle() {
        var createdDate = Date.now.addingTimeInterval(-24*60*60)
        var response = DefaultRequestLoader.Response(data: Data(), createdDate: createdDate)
        XCTAssertTrue(response.isExpired)

        createdDate = Date.now.addingTimeInterval(-25*60*60)
        response = DefaultRequestLoader.Response(data: Data(), createdDate: createdDate)
        XCTAssertTrue(response.isExpired)

        createdDate = Date.now.addingTimeInterval(-23*60*60)
        response = DefaultRequestLoader.Response(data: Data(), createdDate: createdDate)
        XCTAssertFalse(response.isExpired)
    }
}
