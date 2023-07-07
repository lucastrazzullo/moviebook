//
//  WatchlistUndoViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/07/2023.
//

import Foundation
import SwiftUI
import Combine
import MoviebookCommon

@MainActor final class WatchlistUndoViewModel: ObservableObject {

    struct RemovedItem: Identifiable, Equatable {
        let watchlistItem: WatchlistItem
        let imageUrl: URL

        var id: String {
            return imageUrl.absoluteString
        }
    }

    @Published private(set) var removedItem: RemovedItem?

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Public methods

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        watchlist.itemWasRemoved
            .sink { [weak self, weak requestManager] removedItem in
                if let requestManager {
                    self?.handle(removedItem: removedItem, requestManager: requestManager)
                }
            }
            .store(in: &subscriptions)
    }

    func undo(watchlist: Watchlist, removedItem item: RemovedItem) {
        watchlist.update(state: item.watchlistItem.state, forItemWith: item.watchlistItem.id)
        removedItem = nil
    }

    // MARK: Private methods

    private func handle(removedItem: WatchlistItem, requestManager: RequestManager) {
        Task {
            switch removedItem.id {
            case .movie(let id):
                let webService = WebService.movieWebService(requestManager: requestManager)
                let movie = try? await webService.fetchMovie(with: id)
                if let posterUrl = movie?.details.media.posterPreviewUrl {
                    self.removedItem = RemovedItem(watchlistItem: removedItem, imageUrl: posterUrl)
                }
            }
        }
    }
}
