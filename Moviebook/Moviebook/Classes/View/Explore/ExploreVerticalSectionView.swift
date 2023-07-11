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
    @Binding var presentedItem: NavigationItem?

    var body: some View {
        VStack {
            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
            }

            switch viewModel.items {
            case .movies(let movies):
                LazyVStack {
                    ForEach(movies) { movieDetails in
                        MoviePreviewView(details: movieDetails, presentedItem: $presentedItem) {
                            presentedItem = .movieWithIdentifier(movieDetails.id)
                        }
                    }
                }
            case .artists(let artists):
                LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                    ForEach(artists, id: \.self) { artistDetails in
                        ArtistPreviewView(details: artistDetails) {
                            presentedItem = .artistWithIdentifier(artistDetails.id)
                        }
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
            .environment(\.requestManager, MockRequestManager.shared)
            .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}

private struct ExploreSectionViewPreview: View {

    struct DataProvider: ExploreContentDataProvider {
        let title: String = "Mock"
        let subtitle: String? = "Subtitle"
        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestManager: requestManager)
                .fetchMovies(discoverSection: .popular, genres: [], page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestManager) var requestManager
    @ObservedObject var viewModel: ExploreContentViewModel

    var body: some View {
        ScrollView {
            ExploreVerticalSectionView(viewModel: viewModel, presentedItem: .constant(nil))
        }
        .onAppear {
            viewModel.fetch(requestManager: requestManager)
        }
    }

    init() {
        viewModel = ExploreContentViewModel(dataProvider: DataProvider())
    }
}
#endif
