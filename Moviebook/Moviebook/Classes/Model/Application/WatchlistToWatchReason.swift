//
//  WatchlistToWatchReason.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/11/2022.
//

import Foundation

enum WatchlistToWatchReason: Codable, Hashable, Equatable {
    case suggestion(from: String, comment: String)
    case none
}
