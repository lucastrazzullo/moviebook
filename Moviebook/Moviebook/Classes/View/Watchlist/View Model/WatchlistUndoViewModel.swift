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

    private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
    private var timeRemaining: TimeInterval = -1

    private var loadingTask: Task<Void, Never>?
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
        loadingTask?.cancel()
        loadingTask = Task {
            switch removedItem.id {
            case .movie(let id):
                let webService = WebService.movieWebService(requestManager: requestManager)
                let movie = try? await webService.fetchMovie(with: id)
                if let posterUrl = movie?.details.media.posterPreviewUrl,
                   let loadingTask = self.loadingTask, !loadingTask.isCancelled {
                    self.show(removedItem: RemovedItem(watchlistItem: removedItem, imageUrl: posterUrl))
                }
            }
        }
    }

    private func show(removedItem: RemovedItem) {
        self.removedItem = removedItem

        timeRemaining = 5

        timer?.upstream.connect().cancel()
        timer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
        timer?
            .sink { date in
                self.timeRemaining -= 0.1

                if self.timeRemaining <= -1 {
                    self.timeRemaining = -1
                    self.timer?.upstream.connect().cancel()
                    self.removedItem = nil
                }
            }
            .store(in: &subscriptions)
    }
}
