//
//  MovieDetails.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/09/2022.
//

import Foundation

struct MovieDetails: Identifiable, Equatable {
    let id: Movie.ID
    let title: String
    let release: Date?
    let runtime: TimeInterval?
    let overview: String?
    let budget: MoneyValue?
    let revenue: MoneyValue?
    let rating: Rating
    let media: MovieMedia
}
