//
//  EmptyWatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/05/2023.
//

import SwiftUI

struct EmptyWatchlistView: View {

    @MainActor
    private final class ViewModel: ObservableObject {

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
    @Binding var section: WatchlistViewModel.Section

    let onStartDiscoverySelected: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Group {
                switch section {
                case .toWatch:
                    Text("Your watchlist is empty")
                case .watched:
                    Text("You haven't watched a movie yet")
                }
            }
            .font(.title2.bold())
            .foregroundColor(.primary.opacity(0.7))

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

            Group {
                switch section {
                case .toWatch:
                    Button(action: onStartDiscoverySelected) {
                        HStack {
                            Image(systemName: "rectangle.and.text.magnifyingglass")
                            Text("Start your discovery").bold()
                        }
                    }
                case .watched:
                    Button(action: { section = .toWatch }) {
                        HStack {
                            Image(systemName: "text.badge.star")
                            Text("Go to your watchlist").bold()
                        }
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.white)

        }
        .frame(maxWidth: .infinity)
        .padding()
        .padding(.vertical)
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
        .padding(4)
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
                        AsyncImage(url: movieDetails.media.posterPreviewUrl, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }, placeholder: {
                            Color
                                .gray
                                .opacity(0.2)
                        })
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
            }
        }
    }
}

#if DEBUG
struct EmptyWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWatchlistView(section: .constant(.toWatch), onStartDiscoverySelected: {})
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)

        EmptyWatchlistView(section: .constant(.watched), onStartDiscoverySelected: {})
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: []))
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }
}
#endif
