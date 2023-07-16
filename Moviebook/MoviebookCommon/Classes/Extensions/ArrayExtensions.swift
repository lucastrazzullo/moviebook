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
}

extension Array where Element: Equatable {

    public func removeDuplicates() -> [Element] {
        return removeDuplicates(where: { $0 == $1 })
    }
}

extension Array where Element: Hashable {

    public func getMostPopular(bottomCap: Int? = nil, topCap: Int? = nil) -> [Element] {
        var itemsOccurrences: [Element: Int] = [:]
        for item in self {
            itemsOccurrences[item] = (itemsOccurrences[item] ?? 0) + 1
        }

        let sortedItems = itemsOccurrences.keys.sorted(by: { lhs, rhs in
            return itemsOccurrences[lhs] ?? 0 > itemsOccurrences[rhs] ?? 0
        })

        if let bottomCap, let topCap {
            let bottomCap = Swift.min(sortedItems.count, Swift.max(0, bottomCap))
            let topCap = Swift.max(1, Swift.min(sortedItems.count, bottomCap+topCap))
            return Array(sortedItems[bottomCap..<topCap])
        } else if let bottomCap {
            let bottomCap = Swift.min(sortedItems.count, Swift.max(0, bottomCap))
            return Array(sortedItems[bottomCap..<sortedItems.count])
        } else if let topCap {
            let topCap = Swift.max(0, Swift.min(sortedItems.count, topCap))
            return Array(sortedItems[0..<topCap])
        } else {
            return sortedItems
        }
    }
}
