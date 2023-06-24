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
        Section {
            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
            }

            switch viewModel.items {
            case .movies(let movies):
                ForEach(movies) { movieDetails in
                    MoviePreviewView(details: movieDetails) {
                        presentedItem = .movieWithIdentifier(movieDetails.id)
                    }
                }
            case .artists(let artists):
                ForEach(artists, id: \.self) { artistDetails in
                    ArtistPreviewView(details: artistDetails) {
                        presentedItem = .artistWithIdentifier(artistDetails.id)
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
        .listRowSeparator(.hidden)
        .listSectionSeparator(.hidden)
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
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))
    }
}

private struct ExploreSectionViewPreview: View {

    struct DataProvider: ExploreContentDataProvider {
        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestManager: requestManager).fetchPopular(page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestManager) var requestManager
    @ObservedObject var viewModel: ExploreContentViewModel

    var body: some View {
        List {
            ExploreVerticalSectionView(viewModel: viewModel, presentedItem: .constant(nil))
        }
        .listStyle(.inset)
        .onAppear {
            viewModel.fetch(requestManager: requestManager)
        }
    }

    init() {
        viewModel = ExploreContentViewModel(title: "Title", dataProvider: DataProvider())
    }
}
#endif
