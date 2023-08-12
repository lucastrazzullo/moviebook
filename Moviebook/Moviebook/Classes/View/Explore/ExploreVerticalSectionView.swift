//
//  ExploreVerticalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreVerticalSectionView: View {

    @ObservedObject var viewModel: ExploreContentViewModel

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack {
            if let error = viewModel.error {
                RetriableErrorView(error: error)
            }

            switch viewModel.items {
            case .movies(let movies):
                LazyVStack {
                    ForEach(movies) { movieDetails in
                        MoviePreviewView(
                            details: movieDetails,
                            onItemSelected: onItemSelected
                        )
                    }
                }
            case .artists(let artists):
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                    ForEach(artists, id: \.self) { artistDetails in
                        ArtistPreviewView(
                            details: artistDetails,
                            shouldShowCharacter: false,
                            onItemSelected: onItemSelected
                        )
                    }
                }
            }

            if let fetchNextPage = viewModel.fetchNextPage {
                LoadMoreView(action: fetchNextPage)
            }

            if viewModel.isLoading {
                LoaderView()
            }
        }
        .padding()
    }
}

private struct LoadMoreView: View {

    let action: () -> Void

    var body: some View {
        Group {
            Button(action: action) {
                HStack {
                    Text("Load more")
                    Image(systemName: "arrow.down.square.fill")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreSectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        ExploreSectionViewPreview()
            .environment(\.requestLoader, MockRequestLoader.shared)
            .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}

private struct ExploreSectionViewPreview: View {

    struct DataProvider: ExploreContentDataProvider {
        func fetch(requestLoader: RequestLoader, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestLoader: requestLoader)
                .fetchMovies(discoverSection: .popular, genres: [], year: nil, page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestLoader) var requestLoader
    @ObservedObject var viewModel: ExploreContentViewModel

    var body: some View {
        ScrollView {
            ExploreVerticalSectionView(viewModel: viewModel, onItemSelected: { _ in })
        }
        .task {
            await viewModel.fetch(requestLoader: requestLoader) { _ in }
        }
    }

    init() {
        viewModel = ExploreContentViewModel(dataProvider: DataProvider(), title: "Mock", subtitle: "Subtitle", items: .movies([]))
    }
}
#endif
