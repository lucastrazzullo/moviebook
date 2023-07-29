//
//  WatchlistViewItemGroup.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 29/07/2023.
//

import Foundation

struct WatchlistViewItemGroup: Hashable {
    let title: String
    let icon: String
    var items: [WatchlistViewItem]
}
