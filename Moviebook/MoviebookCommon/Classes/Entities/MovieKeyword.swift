//
//  MovieKeyword.swift
//  MoviebookCommon
//
//  Created by Luca Strazzullo on 11/07/2023.
//

import Foundation

public struct MovieKeyword: Identifiable, Equatable, Hashable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}
