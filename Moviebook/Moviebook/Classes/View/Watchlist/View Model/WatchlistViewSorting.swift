//
//  WatchlistViewSorting.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewSorting: String, CaseIterable, Hashable, Equatable {
    case collection
    case lastAdded
    case rating
    case name
    case release

    var label: String {
        switch self {
        case .collection:
            return "By collection"
        case .lastAdded:
            return "Last added"
        case .rating:
            return "Rating"
        case .name:
            return "Name"
        case .release:
            return "Release"
        }
    }

    var image: String {
        switch self {
        case .collection:
            return "square.stack"
        case .lastAdded:
            return "text.line.first.and.arrowtriangle.forward"
        case .rating:
            return "star"
        case .name:
            return "a.circle.fill"
        case .release:
            return "calendar"
        }
    }
}
