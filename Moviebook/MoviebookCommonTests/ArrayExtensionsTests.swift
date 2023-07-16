//
//  ArrayExtensionsTests.swift
//  MoviebookCommonTests
//
//  Created by Luca Strazzullo on 16/07/2023.
//

import XCTest
@testable import MoviebookCommon

final class ArrayExtensionsTests: XCTestCase {

    // MARK: Rotate left

    func testRotateLeft() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        let rotatedArray = array.rotateLeft(distance: 3)
        XCTAssertEqual(rotatedArray, [3, 4, 5, 6, 0, 1, 2])
    }

    func testRotateLeft_withDistance_higherThanCount() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        let rotatedArray = array.rotateLeft(distance: 8)
        XCTAssertEqual(rotatedArray, [1, 2, 3, 4, 5, 6, 0])
    }

    func testRotateLeft_withDistance_higherThanCountThreeTimes() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        let rotatedArray = array.rotateLeft(distance: 22)
        XCTAssertEqual(rotatedArray, [1, 2, 3, 4, 5, 6, 0])
    }

    func testRotateLeft_withDistance_equalToCount() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        let rotatedArray = array.rotateLeft(distance: 7)
        XCTAssertEqual(rotatedArray, [0, 1, 2, 3, 4, 5, 6])
    }

    func testRotateLeft_withZeroDistance() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        let rotatedArray = array.rotateLeft(distance: 0)
        XCTAssertEqual(rotatedArray, [0, 1, 2, 3, 4, 5, 6])
    }

    func testRotateLeft_withNegativeDistance() {
        let array = [0, 1, 2, 3, 4, 5, 6]
        let rotatedArray = array.rotateLeft(distance: -3)
        XCTAssertEqual(rotatedArray, [0, 1, 2, 3, 4, 5, 6])
    }

    func testRotateLeft_emptyArray() {
        let array = [Int]()
        let rotatedArray = array.rotateLeft(distance: 3)
        XCTAssertEqual(rotatedArray, [])
    }

    func testRotateLeft_arrayWithOneItem() {
        let array = [1]
        let rotatedArray = array.rotateLeft(distance: 3)
        XCTAssertEqual(rotatedArray, [1])
    }

    // MARK: Remove duplicates

    func testRemoveDuplicates() {
        let array = [0, 0, 1, 2, 2, 3, 4, 5, 6, 6, 6, 7, 8]
        let arrayWithoutDuplicates = array.removeDuplicates()
        XCTAssertEqual(arrayWithoutDuplicates, [0, 1, 2, 3, 4, 5, 6, 7, 8])
    }

    func testRemoveDuplicates_onArrayWithoutDuplicates() {
        let array = [0, 1, 2, 3, 4, 5, 6, 7, 8]
        let arrayWithoutDuplicates = array.removeDuplicates()
        XCTAssertEqual(arrayWithoutDuplicates, [0, 1, 2, 3, 4, 5, 6, 7, 8])
    }

    func testRemoveDuplicates_onEmptyArray() {
        let array = [Int]()
        let arrayWithoutDuplicates = array.removeDuplicates()
        XCTAssertEqual(arrayWithoutDuplicates, [])
    }

    // MARK: Most popular

    func testGetMostPopular() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular()
        XCTAssertEqual(mostPopular, [1, 2, 0, 3])
    }

    func testGetMostPopular_withTopCap() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(topCap: 2)
        XCTAssertEqual(mostPopular, [1, 2])
    }

    func testGetMostPopular_withTopCap_asZero() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(topCap: 0)
        XCTAssertEqual(mostPopular, [])
    }

    func testGetMostPopular_withTopCap_higherThanCount() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(topCap: 12)
        XCTAssertEqual(mostPopular, [1, 2, 0, 3])
    }

    func testGetMostPopular_withTopCap_lowerThanZero() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(topCap: -1)
        XCTAssertEqual(mostPopular, [])
    }

    func testGetMostPopular_withBottomCap_asZero() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: 0)
        XCTAssertEqual(mostPopular, [1, 2, 0, 3])
    }

    func testGetMostPopular_withBottomCap_higherThanCount() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: 12)
        XCTAssertEqual(mostPopular, [])
    }

    func testGetMostPopular_withBottomCap_lowerThanZero() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: -1)
        XCTAssertEqual(mostPopular, [1, 2, 0, 3])
    }

    func testGetMostPopular_withTopAndBottomCap() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: 1, topCap: 3)
        XCTAssertEqual(mostPopular, [2, 0, 3])
    }

    func testGetMostPopular_withTopCapLowerThanBottomCap() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: 3, topCap: 1)
        XCTAssertEqual(mostPopular, [3])
    }

    func testGetMostPopular_withTopCapHigherThanCount() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: 1, topCap: 5)
        XCTAssertEqual(mostPopular, [2, 0, 3])
    }

    func testGetMostPopular_withBottomCapHigherThanCount() {
        let array = [0, 1, 1, 1, 2, 2, 1, 2, 0, 3]
        let mostPopular = array.getMostPopular(bottomCap: 5, topCap: 3)
        XCTAssertEqual(mostPopular, [])
    }
}
