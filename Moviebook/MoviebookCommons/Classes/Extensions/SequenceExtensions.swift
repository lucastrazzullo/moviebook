//
//  SequenceExtensions.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 10/06/2023.
//

import Foundation

extension Array {

    public func rotateLeft(distance: Int) -> [Element] {
        if distance == 0 || distance == self.count { return self }

        var result = self
        let toAppend = result[..<distance]
        result.removeSubrange(..<distance)
        result.append(contentsOf: toAppend)

        return result
    }
}
