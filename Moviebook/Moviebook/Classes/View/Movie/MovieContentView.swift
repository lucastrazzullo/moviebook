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

    @Binding var navigationPath: NavigationPath
    @Binding var presentedItem: NavigationItem?

    let movie: Movie
    let onVideoSelected: (MovieVideo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            HeaderView(
                details: movie.details,
                onPlayTrailer: onVideoSelected
            )

            MovieWatchlistStateView(
                movieId: movie.id,
                movieReleaseDate: movie.details.release,
                movieBackdropPreviewUrl: movie.details.media.backdropPreviewUrl
            )

            if let overview = movie.details.overview, !overview.isEmpty {
                ExpandibleOverviewView(
                    isExpanded: $isOverviewExpanded,
                    overview: overview
                )
            }

            if !movie.watch.isEmpty {
                WatchProvidersView(watch: movie.watch)
            }

            if !specs.isEmpty {
                SpecsView(title: "Info", items: specs)
            }

            if let collection = movie.collection, let list = collection.list, !list.isEmpty {
                MovieCollectionView(
                    presentedItem: $presentedItem,
                    title: "Collection",
                    movies: list,
                    highlightedMovieId: movie.id,
                    onMovieSelected: { identifier in
                        navigationPath.append(NavigationItem.movieWithIdentifier(identifier))
                    }
                )
            }

            if !movie.cast.isEmpty {
                CastView(
                    cast: movie.cast,
                    onArtistSelected: { identifier in
                        navigationPath.append(NavigationItem.artistWithIdentifier(identifier))
                    }
                )
            }
        }
        .padding(4)
        .animation(.default, value: isOverviewExpanded)
    }

    private var specs: [SpecsView.Item] {
        var specs = [SpecsView.Item]()

        if let runtime = movie.details.runtime, runtime > 0 {
            specs.append(.duration(runtime, label: "Runtime"))
        }

        specs.append(.date(movie.details.release, label: "Release date"))

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
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(details.title).font(.title)
                Spacer()
                RatingView(rating: details.rating)
                Text(details.release, format: .dateTime.year()).font(.caption)
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
                .background(.yellow, in: RoundedRectangle(cornerRadius: 24))
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
            .font(.title2)
            .padding()

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

    @Binding var presentedItem: NavigationItem?

    let title: String
    let movies: [MovieDetails]
    let highlightedMovieId: Movie.ID?
    let onMovieSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .padding(.horizontal)

            LazyVStack(spacing: 0) {
                ForEach(movies) { movieDetails in
                    HStack(spacing: 12) {
                        Text("\((movies.firstIndex(of: movieDetails) ?? 0) + 1)")
                            .font(.title3.bold())
                            .padding(8)
                            .background {
                                if highlightedMovieId == movieDetails.id {
                                    Circle()
                                        .foregroundColor(.green)
                                }
                            }

                        MoviePreviewView(details: movieDetails, presentedItem: $presentedItem) {
                            if highlightedMovieId != movieDetails.id {
                                onMovieSelected(movieDetails.id)
                            }
                        }
                    }
                    .padding(8)
                    .background {
                        if let index = movies.firstIndex(of: movieDetails), index % 2 == 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.ultraThinMaterial.opacity(0.4))
                        }
                    }
                }
            }
        }
        .foregroundColor(.white)
        .padding(4)
        .padding(.vertical)
        .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.8)))
    }
}

private struct CastView: View {

    let cast: [ArtistDetails]
    let onArtistSelected: (Artist.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Cast")
                .font(.title2)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(), GridItem(), GridItem()]) {
                ForEach(cast) { artistDetails in
                    ArtistPreviewView(details: artistDetails, shouldShowCharacter: true, onSelected: {
                        onArtistSelected(artistDetails.id)
                    })
                }
            }
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct MovieContentView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            MovieContentViewPreview()
                .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .empty))
                .environment(\.requestManager, MockRequestManager.shared)
        }
    }
}

private struct MovieContentViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var movie: Movie?

    var body: some View {
        Group {
            if let movie {
                MovieContentView(
                    navigationPath: .constant(NavigationPath()),
                    presentedItem: .constant(nil),
                    movie: movie,
                    onVideoSelected: { _ in }
                )
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = WebService.movieWebService(requestManager: requestManager)
            movie = try! await webService.fetchMovie(with: 353081)
        }
    }
}
#endif
