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
        if !viewModel.items.isEmpty || viewModel.error != nil || viewModel.isLoading {
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
                            Group {
                                switch layout {
                                case .multirows:
                                    let rows: [GridItem] = {
                                        let numberOfRows = viewModel.isLoading ? 3 : min(3, viewModel.items.count)
                                        switch viewModel.items {
                                        case .movies:
                                            return (0..<numberOfRows).map { _ in
                                                GridItem(.fixed(100), spacing: 16)
                                            }
                                        case .artists:
                                            return (0..<numberOfRows).map { _ in
                                                GridItem(.fixed(150), spacing: 16)
                                            }
                                        }
                                    }()
                                    LazyHGrid(rows: rows, spacing: 16) {
                                        switch viewModel.items {
                                        case .movies(let movies):
                                            if movies.isEmpty, viewModel.isLoading {
                                                ForEach(0..<rows.count, id: \.self) { index in
                                                    LoadingItem().frame(width: geometry.frame(in: .global).size.width * 0.85)
                                                }
                                            } else {
                                                ForEach(movies) {  movieDetails in
                                                    MoviePreviewView(details: movieDetails, presentedItem: $presentedItem, style: .backdrop) {
                                                        presentedItem = .movieWithIdentifier(movieDetails.id)
                                                    }
                                                    .frame(width: geometry.frame(in: .global).size.width * 0.85)
                                                }
                                            }
                                        case .artists(let artists):
                                            if artists.isEmpty, viewModel.isLoading {
                                                ForEach(0..<rows.count, id: \.self) { index in
                                                    LoadingItem().frame(width: geometry.frame(in: .global).size.width / 4)
                                                }
                                            } else {
                                                ForEach(artists) { artistDetails in
                                                    ArtistPreviewView(details: artistDetails, shouldShowCharacter: false) {
                                                        presentedItem = .artistWithIdentifier(artistDetails.id)
                                                    }
                                                    .frame(width: geometry.frame(in: .global).size.width / 4)
                                                }
                                            }
                                        }
                                    }
                                case .shelf:
                                    LazyHStack {
                                        switch viewModel.items {
                                        case .movies(let movies):
                                            if movies.isEmpty, viewModel.isLoading {
                                                ForEach(0..<Int(floor(geometry.frame(in: .global).size.width / 120)), id: \.self) { index in
                                                    LoadingItem().frame(width: 180, height: 240)
                                                }
                                            } else {
                                                ForEach(movies) { movieDetails in
                                                    MovieShelfPreviewView(
                                                        presentedItem: $presentedItem,
                                                        movieDetails: movieDetails,
                                                        watchlistIdentifier: .movie(id: movieDetails.id)
                                                    )
                                                    .frame(height: 240)
                                                }
                                            }
                                        case .artists(let artists):
                                            if artists.isEmpty, viewModel.isLoading {
                                                ForEach(0..<Int(floor(geometry.frame(in: .global).size.width / 120)), id: \.self) { index in
                                                    LoadingItem().frame(width: 180, height: 240)
                                                }
                                            } else {
                                                LazyHStack {
                                                    ForEach(artists) { artistDetails in
                                                        ArtistPreviewView(details: artistDetails, shouldShowCharacter: false) {
                                                            presentedItem = .artistWithIdentifier(artistDetails.id)
                                                        }
                                                        .frame(height: 240)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .opacity(viewModel.isLoading ? 0.5 : 1)
                .disabled(viewModel.isLoading)
            }
        }
    }
}

private struct LoadingItem: View {

    @State private var opacity: CGFloat = 0.7

    var body: some View {
        Rectangle()
            .background(.quaternary)
            .overlay(.white.opacity(opacity))
            .cornerRadius(12)
            .onAppear {
                opacity = 0.3
            }
            .animation(.linear(duration: 1).repeatForever().delay(Double.random(in: 0...1)), value: opacity)
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
