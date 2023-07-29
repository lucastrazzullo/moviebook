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

    var id: AnyHashable {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.id
        }
    }

    var name: String {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.title
        }
    }

    var releaseDate: Date {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.releaseDate
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

    let watchlistReference: WatchlistItemIdentifier

    let id: Movie.ID
    let title: String
    let runtime: TimeInterval?
    let backdropUrl: URL
    let releaseDate: Date
    let addedDate: Date
    let rating: Rating
    let genres: [MovieGenre]

    init(movie: Movie, watchlistItem: WatchlistItem) {
        self.watchlistReference = watchlistItem.id

        self.id = movie.id
        self.title = movie.details.title
        self.runtime = movie.details.runtime
        self.backdropUrl = movie.details.media.backdropPreviewUrl
        self.releaseDate = movie.details.localisedReleaseDate()
        self.genres = movie.genres

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
