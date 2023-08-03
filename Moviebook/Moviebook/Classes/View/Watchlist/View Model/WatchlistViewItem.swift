//
//  WatchlistViewItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewItem: Hashable {
    case movie(WatchlistViewMovieItem)

    // MARK: View properties

    var id: WatchlistItemIdentifier {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.id
        }
    }

    var name: String {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.details.title
        }
    }

    var imageUrl: URL {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.details.media.backdropPreviewUrl
        }
    }

    var releaseDate: Date {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.details.localisedReleaseDate()
        }
    }

    var addedDate: Date {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.addedDate
        }
    }

    var rating: Rating {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.rating
        }
    }
}

struct WatchlistViewMovieItem: Hashable {

    let id: WatchlistItemIdentifier
    let details: MovieDetails
    let addedDate: Date
    let rating: Rating
    let genres: [MovieGenre]
    let collection: MovieCollection?

    init(movie: Movie, watchlistItem: WatchlistItem) {
        self.id = watchlistItem.id
        self.details = movie.details
        self.genres = movie.genres
        self.collection = movie.collection

        switch watchlistItem.state {
        case .toWatch(let info):
            addedDate = info.date
        case .watched(let info):
            addedDate = info.date
        }

        switch watchlistItem.state {
        case .toWatch:
            rating = movie.details.rating
        case .watched(let info):
            rating = Rating(value: Float(info.rating ?? 0), quota: movie.details.rating.quota)
        }
    }
}
