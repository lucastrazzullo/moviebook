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
    case movieCollection(WatchlistViewMovieCollectionItem)

    // MARK: View properties

    var id: AnyHashable {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.id
        case .movieCollection(let watchlistViewMovieCollectionItem):
            return watchlistViewMovieCollectionItem.id
        }
    }

    var name: String {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.title
        case .movieCollection(let watchlistViewMovieCollectionItem):
            return watchlistViewMovieCollectionItem.name
        }
    }

    var releaseDate: Date {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.releaseDate
        case .movieCollection(let watchlistViewMovieCollectionItem):
            return watchlistViewMovieCollectionItem.releaseDate
        }
    }

    var addedDate: Date {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.addedDate
        case .movieCollection(let watchlistViewMovieCollectionItem):
            return watchlistViewMovieCollectionItem.addedDate
        }
    }

    var rating: Rating {
        switch self {
        case .movie(let watchlistViewMovieItem):
            return watchlistViewMovieItem.rating
        case .movieCollection(let watchlistViewMovieCollectionItem):
            return watchlistViewMovieCollectionItem.rating
        }
    }
}

struct WatchlistViewMovieCollectionItem: Hashable {

    var id: MovieCollection.ID {
        collection.id
    }
    var name: String {
        collection.name
    }

    let releaseDate: Date
    let addedDate: Date
    let rating: Rating

    let collection: MovieCollection
    var items: [WatchlistViewMovieItem]

    init?(collection: MovieCollection, items: [WatchlistViewMovieItem]) {
        guard !items.isEmpty else { return nil }

        self.collection = collection
        self.releaseDate = items.sorted(by: { $0.releaseDate > $1.releaseDate }).first!.releaseDate
        self.addedDate = items.sorted(by: { $0.addedDate > $1.addedDate }).first!.addedDate
        self.rating = Rating(value: items.reduce(0, { $0 + $1.rating.value }) / Float(items.count), quota: items[0].rating.quota)
        self.items = items
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
