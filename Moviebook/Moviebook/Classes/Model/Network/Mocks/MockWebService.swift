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
        let movieUrl = try! MovieWebService.URLFactory.makeMovieUrl(movieIdentifier: identifier)
        let movieData = try! MockServer().data(from: movieUrl)
        var movie = try! MovieWebService.Parser.parseMovie(data: movieData)

        if let identifier = movie.collection?.id {
            if let movieCollectionUrl = try? MovieWebService.URLFactory.makeMovieCollectionUrl(collectionIdentifier: identifier),
               let movieCollectionData = try? MockServer().data(from: movieCollectionUrl) {
                movie.collection = try? MovieWebService.Parser.parseCollection(data: movieCollectionData)
            }
        }

        return movie
    }

    static func artist(with identifier: Artist.ID) -> Artist {
        let url = try! ArtistWebService.URLFactory.makeArtistUrl(artistIdentifier: identifier)
        let data = try! MockServer().data(from: url)
        let artist = try! ArtistWebService.Parser.parseArtist(data: data)

        return artist
    }
}
#endif
