//
//  WatchlistPrompt.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/05/2023.
//

import SwiftUI
import Combine

enum WatchlistPrompt: Identifiable, Equatable {
    case suggestion(item: WatchlistItem)
    case rating(item: WatchlistItem)
    case undo(removeItem: WatchlistItem)

    var id: WatchlistItemIdentifier {
        switch self {
        case .suggestion(let item):
            return item.id
        case .rating(let item):
            return item.id
        case .undo(let removeItem):
            return removeItem.id
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

private struct WatchlistPromptView: View {

    let prompt: WatchlistPrompt
    let action: () -> Void
    let cancel: () -> Void

    var body: some View {
        Group {
            switch prompt {
            case .suggestion(let item):
                WatchlistPromptItem(watchlistItem: item,
                                    description: "Add a quote from a friend",
                                    actionLabel: "Add",
                                    actionIcon: Image(systemName: "quote.opening"),
                                    action: action,
                                    cancel: cancel)
            case .rating(let item):
                WatchlistPromptItem(watchlistItem: item,
                                    description: "Add your own rating",
                                    actionLabel: "Rate",
                                    actionIcon: Image(systemName: "star"),
                                    action: action,
                                    cancel: cancel)
            case .undo(let removeItem):
                WatchlistPromptItem(watchlistItem: removeItem,
                                    description: "Removed from watchlist",
                                    actionLabel: "Undo",
                                    actionIcon: Image(systemName: "arrow.uturn.backward"),
                                    action: action,
                                    cancel: cancel)
            }
        }
        .id(prompt.id)
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

    @MainActor private final class TimerController: ObservableObject {

        private let time: TimeInterval = 5
        private var timer: Publishers.Autoconnect<Timer.TimerPublisher>?
        private var subscriptions: Set<AnyCancellable> = []

        @Published private(set) var timeRemaining: TimeInterval = -1

        private var onComplete: (() -> Void)?

        func start(onComplete: @escaping () -> Void) {
            self.onComplete = onComplete
            self.timeRemaining = time

            self.timer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
            self.timer?
                .sink { date in
                    self.timeRemaining -= 0.1

                    if self.timeRemaining <= -1 {
                        self.timeRemaining = -1
                        self.timer?.upstream.connect().cancel()
                        self.onComplete?()
                    }
                }
                .store(in: &subscriptions)
        }
    }

    @Environment(\.requestManager) var requestManager

    @StateObject private var loader: MovieInfoLoader = MovieInfoLoader()
    @StateObject private var timer: TimerController = TimerController()

    let watchlistItem: WatchlistItem
    let description: String
    let actionLabel: String
    let actionIcon: Image
    let action: () -> Void
    let cancel: () -> Void

    var body: some View {
        Group {
            if let movie = loader.movie {
                HStack(spacing: 24) {
                    HStack(spacing: 12) {
                        AsyncImage(url: movie.details.media.posterPreviewUrl) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(movie.details.title)
                                .lineLimit(2)
                                .font(.subheadline)
                            Text(description)
                                .font(.callout)
                                .underline()
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button(action: action) {
                        VStack(spacing: 6) {
                            HStack {
                                actionIcon
                                Text(actionLabel)
                            }

                            ProgressView(value: max(0, timer.timeRemaining), total: 5)
                                .progressViewStyle(.linear)
                                .animation(.linear, value: timer.timeRemaining)
                        }
                    }
                    .tint(Color.accentColor)
                    .fixedSize()
                }
            } else {
                LoaderView()
            }
        }
        .animation(.linear, value: timer.timeRemaining)
        .padding()
        .background(Rectangle().fill(.thinMaterial).ignoresSafeArea())
        .onAppear { timer.start(onComplete: cancel) }
        .task {
            switch watchlistItem.id {
            case .movie(let id):
                try? await self.loader.load(requestManager: requestManager, movieIdentifier: id)
            }
        }
    }
}

private struct WatchlistPromptModifier: ViewModifier {

    @Binding var watchlistPrompt: WatchlistPrompt?

    let action: (WatchlistPrompt) -> Void

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content

            if let watchlistPrompt {
                WatchlistPromptView(
                    prompt: watchlistPrompt,
                    action: {
                        self.watchlistPrompt = nil
                        action(watchlistPrompt)
                    },
                    cancel: {
                        self.watchlistPrompt = nil
                    })
            }
        }
    }
}

extension View {

    func watchlistPrompt(prompt: Binding<WatchlistPrompt?>, action: @escaping (WatchlistPrompt) -> Void) -> some View {
        self.modifier(WatchlistPromptModifier(watchlistPrompt: prompt, action: action))
    }
}

#if DEBUG
struct WatchlistPromptView_Previews: PreviewProvider {
    static let toWatchItem = WatchlistItem.init(id: .movie(id: 954), state: .toWatch(info: .init(date: .now)))
    static let watchedItem = WatchlistItem.init(id: .movie(id: 954), state: .toWatch(info: .init(date: .now)))

    static var previews: some View {
        List {
            Group {
                WatchlistPromptView(
                    prompt: .suggestion(item: toWatchItem),
                    action: {},
                    cancel: {}
                )
                .environment(\.requestManager, MockRequestManager())

                WatchlistPromptView(
                    prompt: .rating(item: watchedItem),
                    action: {},
                    cancel: {}
                )
                .environment(\.requestManager, MockRequestManager())

                WatchlistPromptView(
                    prompt: .undo(removeItem: watchedItem),
                    action: {},
                    cancel: {}
                )
                .environment(\.requestManager, MockRequestManager())
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
#endif
