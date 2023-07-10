//
//  MockWatchlistProvider.swift
//  MoviebookTestSupport
//
//  Created by Luca Strazzullo on 10/07/2023.
//

import Foundation
import MoviebookCommon

@MainActor public final class MockWatchlistProvider {

    public enum Configuration {
        case `default`
        case toWatchItems(withSuggestion: Bool)
        case watchedItems(withSuggestion: Bool, withRating: Bool)
        case empty
    }

    public init() {}

    public func watchlist(configuration: Configuration = .default) -> Watchlist {
        switch configuration {
        case .default:
            return Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: makeSuggestion()))),
                WatchlistItem(id: .movie(id: 616037), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: nil), date: .now)))
            ])
        case .toWatchItems(let withSuggestion):
            let suggestion: WatchlistItemToWatchInfo.Suggestion? = withSuggestion ? makeSuggestion() : nil
            return Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: suggestion))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: suggestion)))
            ])
        case .watchedItems(let withSuggestion, let withRating):
            let suggestion: WatchlistItemToWatchInfo.Suggestion? = withSuggestion ? makeSuggestion() : nil
            let rating: Double? = withRating ? 6.4 : nil
            return Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: suggestion), rating: rating, date: .now))),
                WatchlistItem(id: .movie(id: 616037), state: .watched(info: .init(toWatchInfo: .init(date: .now, suggestion: suggestion), rating: rating, date: .now)))
            ])
        case .empty:
            return Watchlist(items: [])
        }
    }

    private func makeSuggestion() -> WatchlistItemToWatchInfo.Suggestion {
        return WatchlistItemToWatchInfo.Suggestion(owner: "Valerio", comment: "This is a really nice movie. I watched already two times, and can't wait to watch it again!")
    }
}
