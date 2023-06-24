//
//  MovieProduction.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import Foundation

public struct MovieProduction: Equatable, Hashable {
    public let companies: [String]

    public init(companies: [String]) {
        self.companies = companies
    }
}
