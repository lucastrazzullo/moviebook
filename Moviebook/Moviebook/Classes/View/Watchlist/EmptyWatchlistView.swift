//
//  EmptyWatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/05/2023.
//

import SwiftUI
import MoviebookCommon

struct EmptyWatchlistView: View {

    @MainActor private final class ViewModel: ObservableObject {

        @Published var results: [WatchlistViewSection: [MovieDetails]] = [:]

        func start(requestLoader: RequestLoader) async throws {
            let webService = WebService.movieWebService(requestLoader: requestLoader)
            self.results = try await withThrowingTaskGroup(of: (section: WatchlistViewSection, results: [MovieDetails]).self) { group in
                var results: [WatchlistViewSection: [MovieDetails]] = [:]

                for section in  WatchlistViewSection.allCases {
                    group.addTask {
                        switch section {
                        case .toWatch:
                            return (section: section, results: try await webService.fetchMovies(discoverSection: .upcoming, genres: [], page: nil).results)
                        case .watched:
                            return (section: section, results: try await webService.fetchMovies(discoverSection: .popular, genres: [], page: nil).results)
                        }
                    }
                }

                for try await result in group {
                    results[result.section] = result.results
                }

                return results
            }
        }
    }

    @Environment(\.requestLoader) var requestLoader

    @StateObject private var viewModel: ViewModel = ViewModel()

    let section: WatchlistViewSection

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                ListView(items: viewModel.results[section] ?? [])
                    .allowsHitTesting(false)
                    .mask(LinearGradient(
                        gradient: Gradient(
                            stops: [
                                .init(color: .gray, location: 0),
                                .init(color: .gray, location: 0.6),
                                .init(color: .gray.opacity(0), location: 1)
                            ]),
                        startPoint: .top,
                        endPoint: .bottom)
                    )
            }

            VStack {
                switch section {
                case .toWatch:
                    Text("Your watchlist is empty")
                        .font(.title2.bold())
                    HStack {
                        Text("Start your discovery")
                        Image(systemName: "magnifyingglass")
                    }
                case .watched:
                    Text("You haven't watched a movie yet")
                        .font(.title2.bold())
                    HStack {
                        Text("Go to your watchlist")
                        Image(systemName: "text.badge.star")
                    }
                }
            }
            .foregroundColor(.primary.opacity(0.7))

        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.vertical)
        .background(.thinMaterial)
        .task {
            try? await viewModel.start(requestLoader: requestLoader)
        }
    }
}

private struct ListView: View {

    let items: [MovieDetails]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [
                    GridItem(spacing: 4),
                    GridItem(spacing: 4),
                    GridItem(spacing: 4),
                    GridItem(spacing: 4)],
                spacing: 4) {
                    ForEach(items, id: \.self) { movieDetails in
                        RemoteImage(
                            url: movieDetails.media.posterPreviewUrl,
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            },
                            placeholder: {
                                Color
                                    .gray
                                    .opacity(0.2)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
            }
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct EmptyWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWatchlistView(section: .toWatch)
            .environment(\.requestLoader, MockRequestLoader.shared)
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)

        EmptyWatchlistView(section: .watched)
            .environment(\.requestLoader, MockRequestLoader.shared)
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }
}
#endif
