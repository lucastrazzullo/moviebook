//
//  WatchlistViewItemGroup.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 29/07/2023.
//

import Foundation
import MoviebookCommon

struct WatchlistViewItemGroup: Hashable {
    let title: String?
    let icon: String?
    let items: [WatchlistViewItem]
    let expandableItems: [WatchlistViewItem]

    init(title: String?,
         icon: String?,
         items: [WatchlistViewItem],
         expandableItems: [WatchlistViewItem] = []) {
        self.title = title
        self.icon = icon
        self.items = items
        self.expandableItems = expandableItems
    }
}
