//
//  ExploreHorizontalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreHorizontalSectionView<Destination: View>: View {

    @ObservedObject var viewModel: ExploreContentViewModel
    @Binding var presentedItem: NavigationItem?

    let geometry: GeometryProxy

    @ViewBuilder let viewAllDestination: () -> Destination

    var body: some View {
        VStack {
            if !viewModel.items.isEmpty {
                HeaderView(
                    title: viewModel.title,
                    isLoading: viewModel.isLoading,
                    destination: viewModel.error == nil ? viewAllDestination() : nil
                )
                .padding(.horizontal)
                
                Divider()
            }

            if let error = viewModel.error {
                RetriableErrorView(retry: error.retry).padding()
            } else if !viewModel.items.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack {
                        switch viewModel.items {
                        case .movies(let movies):
                            LazyHGrid(rows: [
                                GridItem(.fixed(120)),
                                GridItem(.fixed(120)),
                                GridItem(.fixed(120))
                            ], spacing: 18) {
                                ForEach(movies, id: \.self) { movieDetails in
                                    MoviePreviewView(details: movieDetails, presentedItem: $presentedItem, style: .backdrop) {
                                        presentedItem = .movieWithIdentifier(movieDetails.id)
                                    }
                                    .frame(width: geometry.frame(in: .global).size.width * 0.85)
                                }
                            }
                        case .artists(let artists):
                            LazyHGrid(rows: [
                                GridItem(.fixed(160), spacing: 0),
                                GridItem(.fixed(160), spacing: 0)
                            ]) {
                                ForEach(artists, id: \.self) { artistDetails in
                                    ArtistPreviewView(details: artistDetails) {
                                        presentedItem = .artistWithIdentifier(artistDetails.id)
                                    }
                                    .frame(width: geometry.frame(in: .global).size.width / 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .listRowInsets(EdgeInsets())
    }
}

private struct HeaderView<Destination: View>: View {

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

            Spacer()

            if let destination {
                NavigationLink(destination: destination) {
                    Text("Show all")
                }
                .fixedSize()
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

    struct MovieDataProvider: ExploreContentDataProvider {
        var title: String = "Movies"
        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestManager: requestManager)
                .fetch(discoverSection: .popular, genres: [], page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    struct ArtistDataProvider: ExploreContentDataProvider {
        var title: String = "Artists"
        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.artistWebService(requestManager: requestManager)
                .fetchPopular(page: page)
            return (results: .artists(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestManager) var requestManager
    @StateObject var moviesViewModel: ExploreContentViewModel
    @StateObject var artistsViewModel: ExploreContentViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                ExploreHorizontalSectionView(
                    viewModel: artistsViewModel,
                    presentedItem: .constant(nil),
                    geometry: geometry,
                    viewAllDestination: { EmptyView() })

                ExploreHorizontalSectionView(
                    viewModel: moviesViewModel,
                    presentedItem: .constant(nil),
                    geometry: geometry,
                    viewAllDestination: { EmptyView() })
            }
        }
        .onAppear {
            moviesViewModel.fetch(requestManager: requestManager)
            artistsViewModel.fetch(requestManager: requestManager)
        }
    }

    init() {
        _moviesViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: MovieDataProvider()))
        _artistsViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: ArtistDataProvider()))
    }
}
#endif
