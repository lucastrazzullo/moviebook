//
//  MockWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 06/11/2022.
//

import Foundation

#if DEBUG
enum MockWebService {

    static func movie(with identifier: Movie.ID) -> Movie {
        let movieData = try! MockServer().data(from: MovieWebService.URLFactory.makeMovieUrl(movieIdentifier: identifier))
        var movie = try! JSONDecoder().decode(Movie.self, from: movieData)

        if let identifier = movie.collection?.id {
            if let movieCollectionData = try? MockServer().data(from: MovieWebService.URLFactory.makeMovieCollectionUrl(collectionIdentifier: identifier)) {
                movie.collection = try? JSONDecoder().decode(MovieCollection.self, from: movieCollectionData)
            }
        }

        return movie
    }
}
#endif
