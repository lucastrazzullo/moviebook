//
//  ExploreHorizontalSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 16/05/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreHorizontalSectionView<Destination: View>: View {

    enum Layout {
        case shelf
        case multirows
    }

    @ObservedObject var viewModel: ExploreContentViewModel
    @Binding var presentedItem: NavigationItem?

    let layout: Layout
    let geometry: GeometryProxy

    @ViewBuilder let viewAllDestination: () -> Destination

    var body: some View {
        if !viewModel.items.isEmpty || viewModel.error != nil {
            VStack {
                VStack {
                    HeaderView(
                        title: viewModel.title,
                        subtitle: viewModel.subtitle,
                        isLoading: viewModel.isLoading,
                        destination: viewModel.error == nil ? viewAllDestination() : nil
                    )
                    .padding(.horizontal)
                    
                    Divider()
                }
                .padding(.vertical)

                Group {
                    if let error = viewModel.error {
                        RetriableErrorView(retry: error.retry).padding()
                    } else {
                        switch viewModel.items {
                        case .movies(let movies):
                            switch layout {
                            case .multirows:
                                PagedHorizontalGridView(
                                    items: movies,
                                    spacing: 16,
                                    pageWidth: geometry.frame(in: .global).size.width * 0.85,
                                    rows: 3,
                                    itemView: { movieDetails in
                                        MoviePreviewView(details: movieDetails, presentedItem: $presentedItem, style: .backdrop) {
                                            presentedItem = .movieWithIdentifier(movieDetails.id)
                                        }
                                        .frame(width: geometry.frame(in: .global).size.width * 0.85)
                                    }
                                )
                            case .shelf:
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(movies) { movieDetails in
                                            MovieShelfPreviewView(
                                                presentedItem: $presentedItem,
                                                movieDetails: movieDetails,
                                                watchlistIdentifier: .movie(id: movieDetails.id)
                                            )
                                        }
                                    }
                                    .frame(height: 240)
                                    .padding(.horizontal)
                                }
                            }

                        case .artists(let artists):
                            switch layout {
                            case .multirows:
                                PagedHorizontalGridView(
                                    items: artists,
                                    spacing: 16,
                                    pageWidth: geometry.frame(in: .global).size.width * 0.8,
                                    rows: 2,
                                    itemView: { artistDetails in
                                        ArtistPreviewView(details: artistDetails) {
                                            presentedItem = .artistWithIdentifier(artistDetails.id)
                                        }
                                        .frame(width: geometry.frame(in: .global).size.width / 4)
                                        .frame(height: 160)
                                    }
                                )
                            case .shelf:
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(artists) { artistDetails in
                                            ArtistPreviewView(details: artistDetails) {
                                                presentedItem = .artistWithIdentifier(artistDetails.id)
                                            }
                                        }
                                    }
                                    .frame(height: 240)
                                    .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
                .opacity(viewModel.isLoading ? 0.5 : 1)
                .disabled(viewModel.isLoading)
            }
        }
    }
}

private struct HeaderView<Destination: View>: View {

    let title: String
    let subtitle: String?
    let isLoading: Bool
    let destination: Destination?

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 4) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

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
        .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}

private struct ExploreHorizontalSectionViewPreview: View {

    struct MovieDataProvider: ExploreContentDataProvider {
        let title: String = "Movies"
        let subtitle: String? = "Subtitle"
        func fetch(requestManager: RequestManager, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestManager: requestManager)
                .fetchMovies(discoverSection: .popular, genres: [], page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    struct ArtistDataProvider: ExploreContentDataProvider {
        var title: String = "Artists"
        let subtitle: String? = "Subtitle"
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
                VStack {
                    ExploreHorizontalSectionView(
                        viewModel: moviesViewModel,
                        presentedItem: .constant(nil),
                        layout: .shelf,
                        geometry: geometry,
                        viewAllDestination: { EmptyView() })

                    ExploreHorizontalSectionView(
                        viewModel: moviesViewModel,
                        presentedItem: .constant(nil),
                        layout: .multirows,
                        geometry: geometry,
                        viewAllDestination: { EmptyView() })

                    ExploreHorizontalSectionView(
                        viewModel: artistsViewModel,
                        presentedItem: .constant(nil),
                        layout: .multirows,
                        geometry: geometry,
                        viewAllDestination: { EmptyView() })

                    ExploreHorizontalSectionView(
                        viewModel: artistsViewModel,
                        presentedItem: .constant(nil),
                        layout: .shelf,
                        geometry: geometry,
                        viewAllDestination: { EmptyView() })
                }
            }
        }
        .task {
            await moviesViewModel.fetch(requestManager: requestManager)
            await artistsViewModel.fetch(requestManager: requestManager)
        }
    }

    init() {
        _moviesViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: MovieDataProvider()))
        _artistsViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: ArtistDataProvider()))
    }
}
#endif
