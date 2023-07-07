//
//  ExploreHorizontalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreHorizontalSectionView<Destination: View>: View {

    private let rows: [GridItem] = [
        GridItem(.fixed(120)),
        GridItem(.fixed(120)),
        GridItem(.fixed(120))
    ]

    @ObservedObject var viewModel: ExploreContentViewModel
    @Binding var presentedItem: NavigationItem?

    let pageWidth: CGFloat

    @ViewBuilder let viewAllDestination: () -> Destination

    var body: some View {
        Section(header: ExploreHorizontalSectionHeaderView(
            title: viewModel.title,
            isLoading: viewModel.isLoading,
            destination: viewModel.error == nil ? viewAllDestination() : nil)) {
            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, spacing: 18) {
                        switch viewModel.items {
                        case .movies(let movies):
                            ForEach(movies, id: \.self) { movieDetails in
                                MoviePreviewView(details: movieDetails, presentedItem: $presentedItem, style: .backdrop) {
                                    presentedItem = .movieWithIdentifier(movieDetails.id)
                                }
                                .frame(width: pageWidth * 0.8)
                            }
                        case .artists(let artists):
                            ForEach(artists, id: \.self) { artistDetails in
                                ArtistPreviewView(details: artistDetails) {
                                    presentedItem = .artistWithIdentifier(artistDetails.id)
                                }
                                .frame(width: pageWidth * 0.8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .listRowInsets(EdgeInsets())
            }
        }
        .listSectionSeparator(.hidden, edges: .bottom)
    }
}

private struct ExploreHorizontalSectionHeaderView<Destination: View>: View {

    let title: String
    let isLoading: Bool
    let destination: Destination?

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)

            if isLoading {
                ProgressView()
            }

            if let destination {
                Spacer()
                NavigationLink(destination: destination) {
                    Text("Show all")
                }
            }
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreHorizontalSectionView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            ExploreHorizontalSectionViewPreview()
        }
        .environment(\.requestManager, MockRequestManager.shared)
        .environmentObject(Watchlist(items: [
            WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
            WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
        ]))
    }
}

private struct ExploreHorizontalSectionViewPreview: View {

    struct DataProvider: ExploreContentDataProvider {
        func fetch(requestManager: RequestManager, genre: MovieGenre.ID?, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestManager: requestManager).fetch(discoverSection: .popular, genre: nil, page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestManager) var requestManager
    @StateObject var viewModel: ExploreContentViewModel

    var body: some View {
        GeometryReader { geometry in
            List {
                ExploreHorizontalSectionView(
                    viewModel: viewModel,
                    presentedItem: .constant(nil),
                    pageWidth: geometry.size.width,
                    viewAllDestination: { EmptyView() })
            }
        }
        .listStyle(.inset)
        .onAppear {
            viewModel.fetch(requestManager: requestManager, genre: nil)
        }
    }

    init() {
        _viewModel = StateObject(wrappedValue: ExploreContentViewModel(title: "Title", dataProvider: DataProvider()))
    }
}
#endif
