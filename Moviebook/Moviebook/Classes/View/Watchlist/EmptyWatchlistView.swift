//
//  EmptyWatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/05/2023.
//

import SwiftUI
import MoviebookCommons

struct EmptyWatchlistView: View {

    @MainActor private final class ViewModel: ObservableObject {

        @Published var results: [WatchlistViewModel.Section: [MovieDetails]] = [:]

        func start(requestManager: RequestManager) async throws {
            let webService = MovieWebService(requestManager: requestManager)
            self.results = try await withThrowingTaskGroup(of: (section: WatchlistViewModel.Section, results: [MovieDetails]).self) { group in
                var results: [WatchlistViewModel.Section: [MovieDetails]] = [:]

                for section in  WatchlistViewModel.Section.allCases {
                    group.addTask {
                        switch section {
                        case .toWatch:
                            return (section: section, results: try await webService.fetchUpcoming(page: nil).results)
                        case .watched:
                            return (section: section, results: try await webService.fetchPopular(page: nil).results)
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

    @Environment(\.requestManager) var requestManager

    @StateObject private var viewModel: ViewModel = ViewModel()

    let section: WatchlistViewModel.Section

    var body: some View {
        GeometryReader { geometry in
            let bottomSpacing = geometry.safeAreaInsets.bottom + 32

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
            .padding(.bottom, bottomSpacing)
            .background(.thinMaterial)
        }
        .task {
            try? await viewModel.start(requestManager: requestManager)
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
struct EmptyWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWatchlistView(section: .toWatch)
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)

        EmptyWatchlistView(section: .watched)
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }
}
#endif
