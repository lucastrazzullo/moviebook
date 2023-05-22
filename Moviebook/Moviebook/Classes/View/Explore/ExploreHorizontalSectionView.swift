//
//  ExploreHorizontalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI

struct ExploreHorizontalSectionView<Destination: View>: View {

    private let rows: [GridItem] = [
        GridItem(.fixed(120)),
        GridItem(.fixed(120)),
        GridItem(.fixed(120))
    ]

    @ObservedObject var viewModel: ExploreContentViewModel
    @Binding var presentedItem: NavigationItem?

    @ViewBuilder let viewAllDestination: () -> Destination

    var body: some View {
        Section(header: HeaderView(title: viewModel.title, isLoading: viewModel.isLoading, shouldShowAll: viewModel.error == nil, destination: viewAllDestination)) {
            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows) {
                        switch viewModel.items {
                        case .movies(let movies):
                            ForEach(movies, id: \.self) { movieDetails in
                                MoviePreviewView(details: movieDetails, style: .backdrop) {
                                    presentedItem = .movieWithIdentifier(movieDetails.id)
                                }
                                .frame(width: 300)
                                .padding(.horizontal)
                            }
                        case .artists(let artists):
                            ForEach(artists, id: \.self) { artistDetails in
                                ArtistPreviewView(details: artistDetails) {
                                    presentedItem = .artistWithIdentifier(artistDetails.id)
                                }
                                .frame(width: 300)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listSectionSeparator(.hidden, edges: .bottom)
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

    struct DataProvider: ExploreContentDataProvider {
        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await MovieWebService(requestManager: requestManager).fetchPopular(page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestManager) var requestManager
    @StateObject var viewModel: ExploreContentViewModel

    var body: some View {
        List {
            ExploreHorizontalSectionView(viewModel: viewModel, presentedItem: .constant(nil), viewAllDestination: { EmptyView() })
        }
        .listStyle(.inset)
        .onAppear {
            viewModel.fetch(requestManager: requestManager)
        }
    }

    init() {
        _viewModel = StateObject(wrappedValue: ExploreContentViewModel(title: "Title", dataProvider: DataProvider()))
    }
}
#endif
