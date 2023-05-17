//
//  ExploreHorizontalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI

struct ExploreHorizontalSectionView: View {

    private let rows: [GridItem] = [
        GridItem(.fixed(120)),
        GridItem(.fixed(120)),
        GridItem(.fixed(120))
    ]

    @ObservedObject var viewModel: ExploreContentViewModel

    let onItemSelected: (Movie.ID) -> Void

    var body: some View {
        Section(header: HeaderView(title: viewModel.title, isLoading: viewModel.isLoading, shouldShowAll: viewModel.error == nil, destination: viewAllDestination)) {
            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows) {
                        ForEach(viewModel.items, id: \.self) { movieDetails in
                            MoviePreviewView(details: movieDetails, style: .backdrop) {
                                onItemSelected(movieDetails.id)
                            }
                            .frame(width: 300)
                        }
                    }
                }

            }
        }
        .listSectionSeparator(.hidden, edges: .bottom)
    }

    @ViewBuilder private func viewAllDestination() -> some View {
        List {
            ExploreVerticalSectionView(viewModel: viewModel, onItemSelected: onItemSelected)
        }
        .listStyle(.inset)
        .scrollIndicators(.hidden)
        .navigationTitle(viewModel.title)
    }
}

private struct HeaderView<Destination: View>: View {

    let title: String
    let isLoading: Bool
    let shouldShowAll: Bool

    @ViewBuilder let destination: () -> Destination

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)

            if isLoading {
                ProgressView()
            }

            if shouldShowAll {
                Spacer()
                NavigationLink(destination: destination) {
                    Text("Show all")
                }
            }
        }
    }
}

#if DEBUG
struct ExploreHorizontalSectionView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            ExploreHorizontalSectionViewPreview()
        }
        .environment(\.requestManager, MockRequestManager())
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
            WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
        ]))
    }
}

private struct ExploreHorizontalSectionViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @StateObject var viewModel: ExploreContentViewModel

    var body: some View {
        List {
            ExploreHorizontalSectionView(viewModel: viewModel, onItemSelected: { _ in })
        }
        .listStyle(.inset)
    }

    init() {
        _viewModel = StateObject(wrappedValue: ExploreContentViewModel(title: "Title", fetchResults: { requestManager, page in
            return try await MovieWebService(requestManager: requestManager).fetchPopular(page: page)
        }))
    }
}
#endif
