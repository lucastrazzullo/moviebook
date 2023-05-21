//
//  WatchlistPrompt.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/05/2023.
//

import SwiftUI

enum WatchlistPrompt: Identifiable, Equatable {
    case suggestion(item: WatchlistItem)
    case rating(item: WatchlistItem)

    var id: WatchlistItemIdentifier {
        switch self {
        case .suggestion(let item):
            return item.id
        case .rating(let item):
            return item.id
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

    var body: some View {
        Group {
            switch prompt {
            case .suggestion(let item):
                WatchlistPromptItem(watchlistItem: item,
                                    description: "Add a suggestion",
                                    actionLabel: "Add",
                                    action: action)
            case .rating(let item):
                WatchlistPromptItem(watchlistItem: item,
                                    description: "Add your own rating",
                                    actionLabel: "Add",
                                    action: action)
            }
        }
        .id(prompt.id)
    }
}

private struct WatchlistPromptItem: View {

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
                        HStack {
                            Image(systemName: "plus")
                            Text(actionLabel)
                        }
                    }
                    .tint(Color.accentColor)
                    .fixedSize()
                }
            } else {
                LoaderView()
            }
        }
        .padding()
        .background(Rectangle().fill(.thinMaterial).ignoresSafeArea())
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
                WatchlistPromptView(prompt: watchlistPrompt, action: {
                    self.watchlistPrompt = nil
                    action(watchlistPrompt)
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
    static var previews: some View {
        List {
            WatchlistPromptView(prompt: .suggestion(item: .init(id: .movie(id: 954), state: .toWatch(info: .init(date: .now)))), action: {})
                .environment(\.requestManager, MockRequestManager())

            WatchlistPromptView(prompt: .rating(item: .init(id: .movie(id: 954), state: .toWatch(info: .init(date: .now)))), action: {})
                .environment(\.requestManager, MockRequestManager())
        }
        .listStyle(.plain)
    }
}
#endif
