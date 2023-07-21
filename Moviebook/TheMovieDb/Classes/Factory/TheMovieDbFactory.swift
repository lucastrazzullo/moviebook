//
//  TheMovieDbFactory.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

// MARK: - Response with results

enum TheMovieDbFactory {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let localisedDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()

        formatter.formatOptions.insert(.withFractionalSeconds)
        let date = formatter.date(from: "2022-01-05T03:30:00.000Z")

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        return formatter
    }()
}
