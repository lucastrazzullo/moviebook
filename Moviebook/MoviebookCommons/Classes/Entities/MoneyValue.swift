//
//  MoneyValue.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import Foundation

public struct MoneyValue: Equatable, Hashable {
    public let value: Int
    public let currencyCode: String

    public init(value: Int, currencyCode: String) {
        self.value = value
        self.currencyCode = currencyCode
    }
}
