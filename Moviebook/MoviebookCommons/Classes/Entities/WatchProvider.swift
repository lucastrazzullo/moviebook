//
//  WatchProvider.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/05/2023.
//

import Foundation

public struct WatchProvider: Equatable, Hashable {
    public let name: String
    public let iconUrl: URL

    public init(name: String, iconUrl: URL) {
        self.name = name
        self.iconUrl = iconUrl
    }
}
