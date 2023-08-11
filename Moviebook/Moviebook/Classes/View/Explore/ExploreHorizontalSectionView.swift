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

    let layout: Layout
    let containerWidth: CGFloat
    let onItemSelected: (NavigationItem) -> Void

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
                        RetriableErrorView(error: error).padding()
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
                                                GridItem(.fixed(110), spacing: 12)
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
                                                ForEach(0..<rows.count*2, id: \.self) { index in
                                                    LoadingItem().frame(width: containerWidth * 0.85)
                                                }
                                            } else {
                                                ForEach(movies) {  movieDetails in
                                                    MoviePreviewView(
                                                        details: movieDetails,
                                                        style: .backdrop,
                                                        onItemSelected: onItemSelected
                                                    )
                                                    .frame(width: containerWidth * 0.85)
                                                }
                                            }
                                        case .artists(let artists):
                                            if artists.isEmpty, viewModel.isLoading {
                                                ForEach(0..<rows.count*4, id: \.self) { index in
                                                    LoadingItem().frame(width: containerWidth / 4)
                                                }
                                            } else {
                                                ForEach(artists) { artistDetails in
                                                    ArtistPreviewView(
                                                        details: artistDetails,
                                                        shouldShowCharacter: false,
                                                        onItemSelected: onItemSelected
                                                    )
                                                    .frame(width: containerWidth / 4)
                                                }
                                            }
                                        }
                                    }
                                case .shelf:
                                    LazyHStack {
                                        switch viewModel.items {
                                        case .movies(let movies):
                                            if movies.isEmpty, viewModel.isLoading {
                                                ForEach(0..<Int(ceil(containerWidth / 160)), id: \.self) { index in
                                                    LoadingItem().frame(width: 160, height: 240)
                                                }
                                            } else {
                                                ForEach(movies) { movieDetails in
                                                    MovieShelfPreviewView(
                                                        movieDetails: movieDetails,
                                                        onItemSelected: onItemSelected
                                                    )
                                                    .frame(height: 240)
                                                }
                                            }
                                        case .artists(let artists):
                                            if artists.isEmpty, viewModel.isLoading {
                                                ForEach(0..<Int(ceil(containerWidth / 160)), id: \.self) { index in
                                                    LoadingItem().frame(width: 160, height: 240)
                                                }
                                            } else {
                                                LazyHStack {
                                                    ForEach(artists) { artistDetails in
                                                        ArtistPreviewView(
                                                            details: artistDetails,
                                                            shouldShowCharacter: false,
                                                            onItemSelected: onItemSelected
                                                        )
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
                        .font(.heroHeadline)
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
        .environment(\.requestLoader, MockRequestLoader.shared)
        .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}

private struct ExploreHorizontalSectionViewPreview: View {

    struct MovieDataProvider: ExploreContentDataProvider {
        func fetch(requestLoader: RequestLoader, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.movieWebService(requestLoader: requestLoader)
                .fetchMovies(discoverSection: .popular, genres: [], year: nil, page: page)
            return (results: .movies(response.results), nextPage: response.nextPage)
        }
    }

    struct ArtistDataProvider: ExploreContentDataProvider {
        func fetch(requestLoader: RequestLoader, page: Int?) async throws -> (results: ExploreContentItems, nextPage: Int?) {
            let response = try await WebService.artistWebService(requestLoader: requestLoader)
                .fetchPopular(page: page)
            return (results: .artists(response.results), nextPage: response.nextPage)
        }
    }

    @Environment(\.requestLoader) var requestLoader
    @StateObject var moviesViewModel: ExploreContentViewModel
    @StateObject var artistsViewModel: ExploreContentViewModel

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    ExploreHorizontalSectionView(
                        viewModel: moviesViewModel,
                        layout: .shelf,
                        containerWidth: geometry.size.width,
                        onItemSelected: { _ in },
                        viewAllDestination: { EmptyView() })

                    ExploreHorizontalSectionView(
                        viewModel: moviesViewModel,
                        layout: .multirows,
                        containerWidth: geometry.size.width,
                        onItemSelected: { _ in },
                        viewAllDestination: { EmptyView() })

                    ExploreHorizontalSectionView(
                        viewModel: artistsViewModel,
                        layout: .multirows,
                        containerWidth: geometry.size.width,
                        onItemSelected: { _ in },
                        viewAllDestination: { EmptyView() })

                    ExploreHorizontalSectionView(
                        viewModel: artistsViewModel,
                        layout: .shelf,
                        containerWidth: geometry.size.width,
                        onItemSelected: { _ in },
                        viewAllDestination: { EmptyView() })
                }
            }
        }
        .task {
            await moviesViewModel.fetch(requestLoader: requestLoader) { _ in }
            await artistsViewModel.fetch(requestLoader: requestLoader) { _ in }
        }
    }

    init() {
        _moviesViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: MovieDataProvider(), title: "Movies", subtitle: "Mock", items: .movies([])))
        _artistsViewModel = StateObject(wrappedValue: ExploreContentViewModel(dataProvider: ArtistDataProvider(), title: "Artists", subtitle: "Mock", items: .artists([])))
    }
}
#endif
