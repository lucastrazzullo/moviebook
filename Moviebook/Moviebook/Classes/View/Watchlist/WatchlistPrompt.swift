//
//  WatchlistPrompt.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/05/2023.
//

import SwiftUI
import Combine
import MoviebookCommons

private enum WatchlistPrompt: Identifiable, Equatable {
    case suggestion(item: WatchlistItem)
    case rating(item: WatchlistItem)
    case undo(removeItem: WatchlistItem)

    var id: String {
        switch self {
        case .suggestion(let item):
            return "suggestion:\(item.id)"
        case .rating(let item):
            return "rating:\(item.id)"
        case .undo(let removeItem):
            return "undo.remove:\(removeItem.id)"
        }
    }

    var item: WatchlistItem {
        switch self {
        case .suggestion(let item):
            return item
        case .rating(let item):
            return item
        case .undo(let removeItem):
            return removeItem
        }
    }

    var description: String {
        switch self {
        case .suggestion:
            return "Add a quote from a friend"
        case .rating:
            return "Add your own rating"
        case .undo:
            return "Removed from watchlist"
        }
    }

    var actionLabel: String {
        switch self {
        case .suggestion:
            return "Add"
        case .rating:
            return "Rate"
        case .undo:
            return "Undo"
        }
    }

    var actionIcon: Image {
        switch self {
        case .suggestion:
            return Image(systemName: "quote.opening")
        case .rating:
            return Image(systemName: "star.fill")
        case .undo:
            return Image(systemName: "arrow.uturn.backward")
        }
    }

    init?(item: WatchlistItem) {
        switch item.state {
        case .toWatch(let info) where info.suggestion == nil:
            self = .suggestion(item: item)
        case .watched(let info) where info.rating == nil:
            self = .rating(item: item)
        default:
            return nil
        }
    }
}

private enum WatchlistPromptDestination: Identifiable {
    case watchlistAddToWatchReason(itemIdentifier: WatchlistItemIdentifier)
    case watchlistAddRating(itemIdentifier: WatchlistItemIdentifier)

    var id: AnyHashable {
        switch self {
        case .watchlistAddToWatchReason(let item):
            return item.id
        case .watchlistAddRating(let item):
            return item.id
        }
    }
}

private struct WatchlistPromptItem: View {

    @MainActor private final class MovieInfoLoader: ObservableObject {

        @Published var movie: Movie?

        func load(requestManager: RequestManager, movieIdentifier: Movie.ID) async throws {
            let webService = MovieWebService(requestManager: requestManager)
            self.movie = try await webService.fetchMovie(with: movieIdentifier)
        }
    }

    @Environment(\.requestManager) var requestManager

    @StateObject private var loader: MovieInfoLoader = MovieInfoLoader()

    let prompt: WatchlistPrompt
    let timeDuration: TimeInterval
    let timeRemaining: TimeInterval
    let action: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            HStack(spacing: 12) {
                AsyncImage(url: loader.movie?.details.media.posterPreviewUrl) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 60, height: 90)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 6) {
                    Text(loader.movie?.details.title ?? "Loading")
                        .lineLimit(2)
                        .font(.subheadline)
                    Text(prompt.description)
                        .font(.callout)
                        .underline()
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: action) {
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        prompt.actionIcon
                        Text(prompt.actionLabel)
                    }
                    .font(.footnote)
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(
                        ZStack {
                            GeometryReader { reader in
                                let width = max(0, timeRemaining / timeDuration * reader.size.width)
                                Rectangle().fill(Color.secondary)
                                Rectangle().fill(Color.accentColor)
                                    .frame(width: width, alignment: .leading)
                            }
                        }
                        .mask(Capsule())
                    )
                }
            }
            .tint(Color.accentColor)
            .fixedSize()
        }
        .padding()
        .background(Rectangle().fill(.thinMaterial).ignoresSafeArea())
        .task {
            switch prompt.item.id {
            case .movie(let id):
                try? await self.loader.load(requestManager: requestManager, movieIdentifier: id)
            }
        }
    }
}

private struct WatchlistPromptModifier: ViewModifier {

    @MainActor private final class TimerController: ObservableObject {

        private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
        private var timerSubscription: AnyCancellable?
        private var onComplete: (() -> Void)?

        @Published private(set) var timeRemaining: TimeInterval = -1

        let duration: TimeInterval

        init(duration: TimeInterval) {
            self.duration = duration
        }

        func start(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
            self.timeRemaining = duration

            self.timer?.upstream.connect().cancel()
            self.timer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
            self.timerSubscription = self.timer?
                .sink { date in
                    self.timeRemaining -= 0.1

                    if self.timeRemaining <= -1 {
                        self.timeRemaining = -1
                        self.timer?.upstream.connect().cancel()
                        self.onComplete?()
                    }
                }
        }
    }

    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var timer: TimerController
    @State private var watchlistPrompt: WatchlistPrompt?
    @State private var presentedItem: WatchlistPromptDestination?

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let watchlistPrompt {
                    WatchlistPromptItem(
                        prompt: watchlistPrompt,
                        timeDuration: timer.duration,
                        timeRemaining: timer.timeRemaining,
                        action: {
                            self.watchlistPrompt = nil
                            switch watchlistPrompt {
                            case .suggestion(let item):
                                presentedItem = .watchlistAddToWatchReason(itemIdentifier: item.id)
                            case .rating(let item):
                                presentedItem = .watchlistAddRating(itemIdentifier: item.id)
                            case .undo(let removeItem):
                                watchlist.update(state: removeItem.state, forItemWith: removeItem.id)
                            }
                        }
                    )
                    .id(watchlistPrompt.id)
                    .transition(.move(edge: .bottom))
                }
            }
        .animation(.default, value: watchlistPrompt)
        .sheet(item: $presentedItem) { item in
            switch item {
            case .watchlistAddToWatchReason(let itemIdentifier):
                NewToWatchSuggestionView(itemIdentifier: itemIdentifier)
            case .watchlistAddRating(let itemIdentifier):
                NewWatchedRatingView(itemIdentifier: itemIdentifier)
            }
        }
        .onReceive(watchlist.itemDidUpdateState) { item in
            watchlistPrompt = WatchlistPrompt(item: item)
            timer.start(onComplete: { self.watchlistPrompt = nil })
        }
        .onReceive(watchlist.itemWasRemoved) { item in
            watchlistPrompt = .undo(removeItem: item)
            timer.start(onComplete: { self.watchlistPrompt = nil })
        }
    }

    init(duration: TimeInterval) {
        self._timer = StateObject(wrappedValue: TimerController(duration: duration))
    }
}

extension View {

    func watchlistPrompt(duration: TimeInterval) -> some View {
        self.modifier(WatchlistPromptModifier(duration: duration))
    }
}

#if DEBUG
struct WatchlistPromptView_Previews: PreviewProvider {
    static let toWatchItem = WatchlistItem.init(id: .movie(id: 954), state: .toWatch(info: .init(date: .now)))
    static let watchedItem = WatchlistItem.init(id: .movie(id: 954), state: .toWatch(info: .init(date: .now)))

    static var previews: some View {
        List {
            Group {
                WatchlistPromptItem(
                    prompt: .suggestion(item: toWatchItem),
                    timeDuration: 10,
                    timeRemaining: 5,
                    action: {}
                )

                WatchlistPromptItem(
                    prompt: .rating(item: watchedItem),
                    timeDuration: 10,
                    timeRemaining: 5,
                    action: {}
                )

                WatchlistPromptItem(
                    prompt: .undo(removeItem: watchedItem),
                    timeDuration: 10,
                    timeRemaining: 5,
                    action: {}
                )
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .environment(\.requestManager, MockRequestManager())
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
            WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
        ]))
    }
}
#endif
