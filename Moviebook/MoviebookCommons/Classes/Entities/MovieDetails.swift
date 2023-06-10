//
//  MovieDetails.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/09/2022.
//

import Foundation

public struct MovieDetails: Identifiable, Equatable, Hashable {
    public let id: Movie.ID
    public let title: String
    public let release: Date
    public let runtime: TimeInterval?
    public let overview: String?
    public let budget: MoneyValue?
    public let revenue: MoneyValue?
    public let rating: Rating
    public let media: MovieMedia

    public init(id: Movie.ID, title: String, release: Date, runtime: TimeInterval?, overview: String?, budget: MoneyValue?, revenue: MoneyValue?, rating: Rating, media: MovieMedia) {
        self.id = id
        self.title = title
        self.release = release
        self.runtime = runtime
        self.overview = overview
        self.budget = budget
        self.revenue = revenue
        self.rating = rating
        self.media = media
    }
}
