//
//  Configuration.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import Foundation

enum TheMovieDbConfiguration {
    static var language: String { Locale.current.identifier }
    static var region: String { Locale.current.region?.identifier ?? "en-GB" }
    static var currency: String { Locale.current.currency?.identifier ?? "EUR" }
}
