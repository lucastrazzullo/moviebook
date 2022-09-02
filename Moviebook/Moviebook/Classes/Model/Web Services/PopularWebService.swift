//
//  PopularWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

struct PopularWebService {

    func fetch() async throws -> [MoviePreview] {
        return [
            MoviePreview(id: 1, title: "Movie 1"),
            MoviePreview(id: 2, title: "Movie 2")
        ]
    }
}
