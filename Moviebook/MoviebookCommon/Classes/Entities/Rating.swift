//
//  Rating.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/10/2022.
//

import Foundation

public struct Rating: Equatable, Hashable {

    public let value: Float
    public let quota: Float

    public var percentage: Float {
        return value / quota
    }

    public init(value: Float, quota: Float) {
        self.value = value
        self.quota = quota
    }
}
