//
//  WatchlistViewItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import Foundation
import MoviebookCommon

enum WatchlistViewItem: Hashable {
    case movie(WatchlistViewMovieItem, watchlistItem: WatchlistItem?)

    // MARK: View properties

    var watchlistIdentifier: WatchlistItemIdentifier {
        switch self {
        case .movie(let watchlistViewMovieItem, let watchlistItem):
            return watchlistItem?.id ?? .movie(id: watchlistViewMovieItem.details.id)
        }
    }

    var name: String {
        switch self {
        case .movie(let watchlistViewMovieItem, _):
            return watchlistViewMovieItem.details.title
        }
    }

    var backdropUrl: URL {
        switch self {
        case .movie(let watchlistViewMovieItem, _):
            return watchlistViewMovieItem.details.media.backdropPreviewUrl
        }
    }

    var posterUrl: URL {
        switch self {
        case .movie(let watchlistViewMovieItem, _):
            return watchlistViewMovieItem.details.media.posterPreviewUrl
        }
    }

    var releaseDate: Date {
        switch self {
        case .movie(let watchlistViewMovieItem, _):
            return watchlistViewMovieItem.details.localisedReleaseDate()
        }
    }

    var rating: Rating {
        switch self {
        case .movie(let watchlistViewMovieItem, let watchlistItem):
            switch watchlistItem?.state {
            case .toWatch, .none:
                return watchlistViewMovieItem.details.rating
            case .watched(let info):
                return Rating(value: Float(info.rating ?? Double(watchlistViewMovieItem.details.rating.value)), quota: watchlistViewMovieItem.details.rating.quota)
            }
        }
    }

    var position: Int? {
        switch self {
        case .movie(let watchlistViewMovieItem, _):
            if let collection = watchlistViewMovieItem.collection,
               let index = collection.list.firstIndex(where: { $0.id == watchlistViewMovieItem.details.id }) {
                return index + 1
            } else {
                return nil
            }
        }
    }

    var addedDate: Date? {
        switch self {
        case .movie(_, let watchlistItem):
            switch watchlistItem?.state {
            case .toWatch(let info):
                return info.date
            case .watched(let info):
                return info.date
            case .none:
                return nil
            }
        }
    }
}

struct WatchlistViewMovieItem: Hashable {

    let details: MovieDetails
    let genres: [MovieGenre]
    let collection: MovieCollection?

    init(movie: Movie) {
        self.details = movie.details
        self.genres = movie.genres
        self.collection = movie.collection
    }

    init(details: MovieDetails, collection: MovieCollection?) {
        self.details = details
        self.genres = []
        self.collection = collection
    }
}
