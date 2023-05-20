//
//  MoviebookView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import Combine
import CoreSpotlight

@MainActor
private final class ViewModel: ObservableObject {

    private var promptTimer: Publishers.Autoconnect<Timer.TimerPublisher>?
    private var subscriptions: Set<AnyCancellable> = []

    enum Prompt: Equatable {
        case suggestion(item: WatchlistItem)
        case rating(item: WatchlistItem)
    }

    @Published private(set) var prompt: Prompt?
    @Published private(set) var promptTimeRemaining: TimeInterval = -1

    func start(watchlist: Watchlist) {
        watchlist.itemDidUpdateState
            .sink { [weak self] item in
                switch item.state {
                case .toWatch(let info):
                    if info.suggestion == nil {
                        self?.startPrompt(prompt: .suggestion(item: item))
                    }
                case .watched(let info):
                    if info.rating == nil {
                        self?.startPrompt(prompt: .rating(item: item))
                    }
                }
            }
            .store(in: &subscriptions)
    }

    private func startPrompt(prompt: Prompt) {
        self.prompt = prompt
        self.promptTimeRemaining = 5

        self.promptTimer = Timer.publish(every: 0.1, on: .main, in: .default).autoconnect()
        self.promptTimer?
            .sink { date in
                self.promptTimeRemaining -= 0.1

                if self.promptTimeRemaining <= -1 {
                    self.promptTimeRemaining = -1
                    self.prompt = nil
                    self.promptTimer?.upstream.connect().cancel()
                }
            }
            .store(in: &subscriptions)
    }
}

struct MoviebookView: View {

    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var viewModel: ViewModel = ViewModel()

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: NavigationItem? = nil

    var body: some View {
        NavigationView {
            WatchlistView(onExploreSelected: {
                presentedItem = .explore
            }, onMovieSelected: { movie in
                presentedItem = .movie(movie)
            })
            .animation(.easeInOut(duration: 0.8), value: viewModel.prompt)
        }
        .onOpenURL { url in
            if let deeplink = Deeplink(rawValue: url) {
                open(deeplink: deeplink)
            }
        }
        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
            if let deeplink = Spotlight.deeplink(from: userActivity) {
                open(deeplink: deeplink)
            }
        }
        .sheet(item: $presentedItem) { item in
            Navigation(path: $presentedItemNavigationPath, presentingItem: item)
        }
        .onAppear {
            viewModel.start(watchlist: watchlist)
        }
    }

    // MARK: Private helper methods

    private func open(deeplink: Deeplink) {
        switch deeplink {
        case .watchlist:
            presentedItem = nil
        case .movie(let identifier):
            presentedItem = .movieWithIdentifier(identifier)
        case .artist(let identifier):
            presentedItem = .artistWithIdentifier(identifier)
        }
    }
}

private struct PromptView: View {

    let prompt: ViewModel.Prompt
    let timeRemaining: TimeInterval

    var body: some View {
        switch prompt {
        case .suggestion(let item):
            PromptItem(watchlistItem: item,
                       description: "Add a suggestion",
                       timeRemaining: timeRemaining,
                       actionLabel: "Add",
                       action: {})
        case .rating(let item):
            PromptItem(watchlistItem: item,
                       description: "Add your own rating",
                       timeRemaining: timeRemaining,
                       actionLabel: "Add",
                       action: {})
        }
    }
}

private struct PromptItem: View {

    @MainActor
    private final class MovieInfoLoader: ObservableObject {

        @Published var movie: Movie?

        func load(requestManager: RequestManager, movieIdentifier: Movie.ID) async throws {
            let webService = MovieWebService(requestManager: requestManager)
            self.movie = try await webService.fetchMovie(with: movieIdentifier)
        }
    }

    @Environment(\.requestManager) var requestManager

    @StateObject private var loader: MovieInfoLoader = MovieInfoLoader()

    let watchlistItem: WatchlistItem
    let description: String
    let timeRemaining: TimeInterval
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        Group {
            if let movie = loader.movie {
                HStack(spacing: 24) {
                    HStack {
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
                                .font(.headline)
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Button(action: action) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "plus")
                                Text(actionLabel)
                            }
                            ProgressView(value: max(0, timeRemaining), total: 5)
                                .progressViewStyle(.linear)
                                .animation(.linear, value: timeRemaining)
                        }
                    }
                    .tint(Color.accentColor)
                    .fixedSize()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding()
                .background(Rectangle().fill(.background))
            } else {
                LoaderView()
            }
        }
        .task {
            switch watchlistItem.id {
            case .movie(let id):
                try? await self.loader.load(requestManager: requestManager, movieIdentifier: id)
            }
        }
    }
}

#if DEBUG
struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))
    }
}
#endif
