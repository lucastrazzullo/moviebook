//
//  ExploreVerticalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI

struct ExploreVerticalSectionView: View {

    @ObservedObject var viewModel: ExploreContentViewModel

    let onItemSelected: (Movie.ID) -> Void

    var body: some View {
        Section {
            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
            }

            ForEach(viewModel.items) { details in
                MoviePreviewView(details: details) {
                    onItemSelected(details.id)
                }
            }

            if let fetchNextPage = viewModel.fetchNextPage {
                LoadMoreView(action: fetchNextPage)
            }

            if viewModel.isLoading {
                ProgressView()
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
struct ExploreSectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        ExploreSectionViewPreview()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))
    }
}

private struct ExploreSectionViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @ObservedObject var viewModel: ExploreContentViewModel

    var body: some View {
        List {
            ExploreVerticalSectionView(viewModel: viewModel, onItemSelected: { _ in })
        }
        .listStyle(.inset)
    }

    init() {
        viewModel = ExploreContentViewModel(title: "Title", fetchResults: { requestManager, page in
            return try await MovieWebService(requestManager: requestManager).fetchPopular(page: page)
        })
    }
}
#endif
