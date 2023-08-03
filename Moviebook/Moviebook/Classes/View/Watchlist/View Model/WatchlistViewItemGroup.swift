//
//  WatchlistViewItemGroup.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 29/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewItemGroupIdentifier: Hashable {
    case movieCollection(MovieCollection)
    case `default`
}

struct WatchlistViewItemGroup: Identifiable, Hashable {
    let id: WatchlistViewItemGroupIdentifier
    let title: String
    let icon: String
    let items: [WatchlistViewItem]

    init(id: WatchlistViewItemGroupIdentifier = .default,
         title: String,
         icon: String,
         items: [WatchlistViewItem]) {
        self.id = id
        self.title = title
        self.icon = icon
        self.items = items
    }
}
