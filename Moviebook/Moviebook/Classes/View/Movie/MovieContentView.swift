//
//  MovieContentView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI
import MoviebookCommon

struct MovieContentView: View {

    @State private var isOverviewExpanded: Bool = false

    let movie: Movie
    let onItemSelected: (NavigationItem) -> Void
    let onVideoSelected: (MovieVideo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            HeaderView(
                details: movie.details,
                onPlayTrailer: onVideoSelected
            )

            if let overview = movie.details.overview, !overview.isEmpty {
                ExpandibleOverviewView(
                    isExpanded: $isOverviewExpanded,
                    overview: overview
                )
            }

            MovieWatchlistStateView(
                movieId: movie.id,
                movieReleaseDate: movie.details.localisedReleaseDate(),
                movieBackdropPreviewUrl: movie.details.media.backdropPreviewUrl,
                onItemSelected: onItemSelected
            )

            if !specs.isEmpty {
                SpecsView(title: "Info", items: specs)
            }

            if !movie.watch.isEmpty {
                WatchProvidersView(watch: movie.watch)
            }

            MovieRelatedView(
                movieId: movie.id,
                onItemSelected: onItemSelected
            )

            if let collection = movie.collection, !collection.list.isEmpty {
                MovieCollectionView(
                    title: "Collection",
                    movies: collection.list,
                    highlightedMovieId: movie.id,
                    onItemSelected: onItemSelected
                )
            }

            if !movie.cast.isEmpty {
                CastView(
                    cast: movie.cast,
                    onItemSelected: onItemSelected
                )
            }
        }
        .animation(.default, value: isOverviewExpanded)
    }

    private var specs: [SpecsView.Item] {
        var specs = [SpecsView.Item]()

        if let runtime = movie.details.runtime, runtime > 0 {
            specs.append(.duration(runtime, label: "Runtime"))
        }

        specs.append(.date(movie.details.localisedReleaseDate(), label: "Release date"))

        if !movie.genres.isEmpty {
            specs.append(.list(movie.genres.map(\.name), label: "Genres"))
        }

        if !movie.production.companies.isEmpty {
            specs.append(.list(movie.production.companies, label: "Production"))
        }

        if let budget = movie.details.budget, budget.value > 0 {
            specs.append(.currency(budget.value, code: budget.currencyCode, label: "Budget"))
        }

        if let revenue = movie.details.revenue, revenue.value > 0 {
            specs.append(.currency(revenue.value, code: revenue.currencyCode, label: "Incassi"))
        }

        return specs
    }
}

private struct HeaderView: View {

    let details: MovieDetails
    let onPlayTrailer: (MovieVideo) -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(details.title)
                    .font(.hero)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)

                Spacer()

                RatingView(rating: details.rating)

                Text(details.localisedReleaseDate(), format: .dateTime.year())
                    .font(.caption)
            }

            Spacer()

            if let trailer = details.media.videos.first(where: { $0.type == .trailer }) {
                Button(action: { onPlayTrailer(trailer) }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Trailer")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .tint(.black)
                .background(Color.secondaryAccentColor, in: RoundedRectangle(cornerRadius: 24))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct WatchProvidersView: View {

    @State private var currentRegion: String

    let watch: WatchProviders

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Watch providers")
                    .font(.heroHeadline)
                Spacer()
                Picker("Region", selection: $currentRegion) {
                    ForEach(watch.regions, id: \.self) { region in
                        if let localizedRegion = Locale.current.localizedString(forRegionCode: region) {
                            Text(localizedRegion).id(region)
                        }
                    }
                }
            }
            .tint(.primary)
            .padding(.vertical)
            .padding(.leading)

            Group {
                if let collection = watch.collection(for: currentRegion) {
                    if !collection.free.isEmpty {
                        providerList(header: "Free", providers: collection.free)
                    }

                    if !(collection.rent + collection.buy).isEmpty {
                        providerList(header: "Rent or Buy", providers: collection.rent + collection.buy)
                    }
                } else {
                    VStack {
                        Text("This movie has no watch providers yet")
                    }
                }
            }
            .padding(.leading)
            .padding(.bottom)
        }
        .background(.thinMaterial)
        .cornerRadius(8)
        .padding(.horizontal, 4)
    }

    @ViewBuilder private func providerList(header: String, providers: [WatchProvider]) -> some View {
        var uniqueProviders = Set<WatchProvider>(providers)
        let providers = providers.filter { provider in
            if uniqueProviders.contains(provider) {
                uniqueProviders.remove(provider)
                return true
            } else {
                return false
            }
        }
        VStack(alignment: .leading, spacing: 4) {
            Text(header).font(.headline)
            Divider()
            VStack(alignment: .leading, spacing: 18) {
                ForEach(providers, id: \.name) { provider in
                    HStack {
                        RemoteImage(url: provider.iconUrl, content: { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        }, placeholder: {
                            Rectangle().fill(.thinMaterial)
                        })
                        .frame(height: 32)
                        .cornerRadius(8)

                        Text(provider.name)
                            .font(.callout)
                            .padding(.trailing)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    init(watch: WatchProviders) {
        self.watch = watch

        let initialRegion = Locale.current.region?.identifier ?? watch.regions.first ?? "US"
        self._currentRegion = State(initialValue: initialRegion)
    }
}

private struct MovieCollectionView: View {

    let title: String
    let movies: [MovieDetails]
    let highlightedMovieId: Movie.ID?
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.heroHeadline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(movies) { movieDetails in
                        HStack(spacing: 0) {
                            Text("\((movies.firstIndex(of: movieDetails) ?? 0) + 1)")
                                .font(.heroHeadline)
                                .padding(8)
                                .padding(.leading, 8)

                            MovieShelfPreviewView(
                                movieDetails: movieDetails,
                                onItemSelected: onItemSelected
                            )
                            .disabled(highlightedMovieId == movieDetails.id)
                        }
                        .frame(height: 200)
                        .padding(8)
                    }
                }
            }
        }
        .foregroundColor(.white)
        .padding(4)
        .padding(.vertical)
        .background(
            GeometryReader { geometry in
                RemoteImage(
                    url: movies.randomElement()?.media.backdropPreviewUrl,
                    content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                    },
                    placeholder: { Color.black }
                )
                .overlay(Rectangle()
                    .fill(.black.opacity(0.55))
                    .background(.thinMaterial)
                )
                .cornerRadius(8)
            }
        )
        .padding(.horizontal, 4)
    }
}

private struct MovieRelatedView: View {

    @Environment(\.requestLoader) private var requestLoader

    @StateObject private var viewModel: ExploreContentViewModel
    @State private var containerWidth: CGFloat = 0

    private let movieId: Movie.ID
    private let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack {
            if containerWidth > 0 {
                ExploreHorizontalSectionView(
                    viewModel: viewModel,
                    layout: .multirows,
                    containerWidth: containerWidth,
                    onItemSelected: onItemSelected,
                    viewAllDestination: {
                        ScrollView(showsIndicators: false) {
                            ExploreVerticalSectionView(
                                viewModel: viewModel,
                                onItemSelected: onItemSelected
                            )
                        }
                        .navigationTitle(viewModel.title)
                    }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .overlay(GeometryReader { geometry in
            Color.clear.onAppear {
                containerWidth = geometry.size.width
            }
        })
        .task {
            await viewModel.fetch(requestLoader: requestLoader) { dataProvider in
                if let related = dataProvider as? DiscoverRelated {
                    await related.update(
                        referenceMovies: [.init(id: movieId, weight: .neutral)],
                        overrideGenres: [],
                        requestLoader: requestLoader
                    )
                }
            }
        }
    }

    init(movieId: Movie.ID, onItemSelected: @escaping (NavigationItem) -> Void) {
        self._viewModel = StateObject(
            wrappedValue: ExploreContentViewModel(
                dataProvider: DiscoverRelated(),
                title: "Related",
                subtitle: nil,
                items: .movies([])
            )
        )
        self.movieId = movieId
        self.onItemSelected = onItemSelected
    }
}

private struct CastView: View {

    let cast: [ArtistDetails]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Cast")
                .font(.heroHeadline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                ForEach(cast) { artistDetails in
                    ArtistPreviewView(
                        details: artistDetails,
                        shouldShowCharacter: true,
                        onItemSelected: onItemSelected
                    )
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

#if DEBUG
import MoviebookTestSupport

struct MovieContentView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            MovieContentViewPreview()
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
                .environment(\.requestLoader, MockRequestLoader.shared)
        }
    }
}

private struct MovieContentViewPreview: View {

    @Environment(\.requestLoader) var requestLoader
    @State var movie: Movie?

    var body: some View {
        Group {
            if let movie {
                MovieContentView(
                    movie: movie,
                    onItemSelected: { _ in },
                    onVideoSelected: { _ in }
                )
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = WebService.movieWebService(requestLoader: requestLoader)
            movie = try! await webService.fetchMovie(with: 353081)
        }
    }
}
#endif
