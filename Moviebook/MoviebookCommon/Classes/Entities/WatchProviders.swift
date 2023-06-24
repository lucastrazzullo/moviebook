//
//  WatchProviders.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import Foundation

public struct WatchProviders: Equatable, Hashable {

    public let regions: [String]
    public let isEmpty: Bool

    private let collections: [String: WatchProviderCollection]

    public init(collections: [String: WatchProviderCollection]) {
        self.collections = collections
        self.regions = Array(collections.keys).sorted()
        self.isEmpty = regions.isEmpty || collections.values.first(where: { !$0.isEmpty }) == nil
    }

    public func collection(for region: String) -> WatchProviderCollection? {
        return collections[region]
    }
}
