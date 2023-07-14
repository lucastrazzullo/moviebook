//
//  ArrayExtensions.swift
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

extension Array where Element: Hashable {

    public func getMostPopular(cap: Int?) -> [Element] {
        var itemsOccurrences: [Element: Int] = [:]
        for item in self {
            itemsOccurrences[item] = (itemsOccurrences[item] ?? 0) + 1
        }

        let sortedItems = itemsOccurrences.keys.sorted(by: { lhs, rhs in
            return itemsOccurrences[lhs] ?? 0 > itemsOccurrences[rhs] ?? 0
        })

        if let cap, sortedItems.count > cap {
            return Array(sortedItems[0..<cap])
        } else {
            return sortedItems
        }
    }
}
