//
//  Rating.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 28/10/2022.
//

import Foundation

struct Rating: Equatable, Hashable {

    let value: Float
    let quota: Float

    var percentage: Float {
        return value / quota
    }
}
