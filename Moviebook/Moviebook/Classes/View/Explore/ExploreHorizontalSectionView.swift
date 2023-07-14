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
                        ScrollView(.horizontal, showsIndicators: false) {
                            switch viewModel.items {
                            case .movies(let movies):
                                switch layout {
                                case .multirows:
                                    LazyHGrid(rows: (0..<(min(3, movies.count))).map { _ in GridItem(.fixed(100), spacing: 16) }, spacing: 16) {
                                        ForEach(movies) {  movieDetails in
                                            MoviePreviewView(details: movieDetails, presentedItem: $presentedItem, style: .backdrop) {
                                                presentedItem = .movieWithIdentifier(movieDetails.id)
                                            }
                                            .frame(width: geometry.frame(in: .global).size.width * 0.85)
                                        }
                                    }
                                    .padding(.horizontal)
                                case .shelf:
                                    LazyHStack {
                                        ForEach(movies) { movieDetails in
                                            MovieShelfPreviewView(
                                                presentedItem: $presentedItem,
                                                movieDetails: movieDetails,
                                                watchlistIdentifier: .movie(id: movieDetails.id)
                                            )
                                            .frame(height: 240)
                                        }
                                    }
                                    .padding(.horizontal)
                                }

                            case .artists(let artists):
                                switch layout {
                                case .multirows:
                                    LazyHGrid(rows: (0..<2).map { _ in GridItem(.fixed(150), spacing: 16) }, spacing: 16) {
                                        ForEach(artists) { artistDetails in
                                            ArtistPreviewView(details: artistDetails, shouldShowCharacter: false) {
                                                presentedItem = .artistWithIdentifier(artistDetails.id)
                                            }
                                            .frame(width: geometry.frame(in: .global).size.width / 4)
                                        }
                                    }
                                    .padding(.horizontal)
                                case .shelf:
                                    LazyHStack {
                                        ForEach(artists) { artistDetails in
                                            ArtistPreviewView(details: artistDetails, shouldShowCharacter: false) {
                                                presentedItem = .artistWithIdentifier(artistDetails.id)
                                            }
                                            .frame(height: 240)
                                        }
                                    }
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
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.title3)
                        .bold()
                        .foregroundColor(.primary)

                    if isLoading {
                        ProgressView()
                    }
                }

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
            await moviesViewModel.fetch(requestManager: requestManager) { _ in }
            await artistsViewModel.fetch(requestManager: requestManager) { _ in }
        }
    }

    init() {
        _moviesViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: MovieDataProvider()))
        _artistsViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: ArtistDataProvider()))
    }
}
#endif
