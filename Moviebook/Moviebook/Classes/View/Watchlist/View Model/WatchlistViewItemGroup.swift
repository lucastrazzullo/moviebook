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
    let imageUrl: URL?
    let items: [WatchlistViewItem]
    let expandableItems: [WatchlistViewItem]

    init(title: String? = nil,
         icon: String? = nil,
         imageUrl: URL? = nil,
         items: [WatchlistViewItem],
         expandableItems: [WatchlistViewItem] = []) {
        self.title = title
        self.icon = icon
        self.imageUrl = imageUrl
        self.items = items
        self.expandableItems = expandableItems
    }
}
