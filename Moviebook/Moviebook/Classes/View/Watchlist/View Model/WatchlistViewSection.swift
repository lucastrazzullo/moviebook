//
//  WatchlistViewSection.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewSection: String, Identifiable, Hashable, Equatable, CaseIterable {
    case toWatch
    case watched

    var id: String {
        return self.rawValue
    }

    var name: String {
        switch self {
        case .toWatch:
            return NSLocalizedString("WATCHLIST.TO_WATCH.TITLE", comment: "")
        case .watched:
            return NSLocalizedString("WATCHLIST.WATCHED.TITLE", comment: "")
        }
    }

    func belongsToSection(_ item: WatchlistItem) -> Bool {
        switch (self, item.state) {
        case (.toWatch, .toWatch):
            return true
        case (.watched, .watched):
            return true
        default:
            return false
        }
    }
}
