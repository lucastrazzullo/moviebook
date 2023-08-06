//
//  ArrayExtensions.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 10/06/2023.
//

import Foundation

extension Array {
    
    public func rotateLeft(distance: Int) -> [Element] {
        if self.isEmpty || self.count == 1 || distance <= 0 || distance == self.count { return self }

        let distance = distance > self.count ? distance % self.count : distance

        var result = self
        let toAppend = result[..<distance]
        result.removeSubrange(..<distance)
        result.append(contentsOf: toAppend)

        return result
    }

    public func removeDuplicates(where matching: (Element, Element) -> Bool) -> [Element] {
        var result = Array<Element>()

        for element in self {
            if result.contains(where: { matching(element, $0) }) {
                continue
            }

            result.append(element)
        }

        return result
    }

    public func cap(bottom: Int? = nil, top: Int? = nil) -> [Element] {
        guard !self.isEmpty else {
            return self
        }

        if let bottom, let top {
            let bottom = Swift.min(self.count, Swift.max(0, bottom))
            let top = Swift.max(1, Swift.min(self.count, bottom+top))
            return Array(self[bottom..<top])
        } else if let bottom {
            let bottom = Swift.min(self.count, Swift.max(0, bottom))
            return Array(self[bottom..<self.count])
        } else if let top {
            let top = Swift.max(0, Swift.min(self.count, top))
            return Array(self[0..<top])
        } else {
            return self
        }
    }
}

extension Array where Element: Equatable {

    public func removeDuplicates() -> [Element] {
        return removeDuplicates(where: { $0 == $1 })
    }
}

extension Array where Element: Hashable {

    public func getMostPopular() -> [Element] {
        guard !self.isEmpty else {
            return self
        }

        var itemsOccurrences: [Element: Int] = [:]
        for item in self {
            itemsOccurrences[item] = (itemsOccurrences[item] ?? 0) + 1
        }

        let sortedItems = itemsOccurrences.keys.sorted(by: { lhs, rhs in
            return itemsOccurrences[lhs] ?? 0 > itemsOccurrences[rhs] ?? 0
        })

        return sortedItems
    }
}
