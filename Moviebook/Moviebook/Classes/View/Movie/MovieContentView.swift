//
//  MovieContentView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieContentView: View {

    @State private var isOverviewExpanded: Bool = false

    @Binding var navigationPath: NavigationPath

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
                SpecsView(title: "Specs", items: specs)
            }

            if let collection = movie.collection, let list = collection.list, !list.isEmpty {
                MovieCollectionView(
                    title: "Collection",
                    movies: list,
                    highlightedMovieId: movie.id,
                    onMovieSelected: { identifier in
                        navigationPath.append(NavigationItem.movie(movieId: identifier))
                    }
                )
            }

            if !movie.cast.isEmpty {
                CastView(
                    cast: movie.cast,
                    onArtistSelected: { identifier in
                        navigationPath.append(NavigationItem.artist(artistId: identifier))
                    }
                )
            }
        }
        .padding(4)
        .animation(.default, value: isOverviewExpanded)
    }

    private var specs: [SpecsView.Item] {
        var specs = [SpecsView.Item]()

        if let runtime = movie.details.runtime {
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
                .background(RoundedRectangle(cornerRadius: 24).fill(.yellow))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct WatchProvidersView: View {

    let watch: WatchProviderCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Watch providers")
                .font(.title2)


            if !watch.free.isEmpty {
                VStack(alignment: .leading) {
                    Text("Free").font(.headline)
                    providerList(providers: watch.free)
                }
            }

            if !(watch.rent + watch.buy).isEmpty {
                VStack(alignment: .leading) {
                    Text("Rent or Buy").font(.headline)
                    providerList(providers: watch.rent + watch.buy)
                }
            }
        }
        .padding()
        .background(.yellow)
        .cornerRadius(8)
    }

    @ViewBuilder private func providerList(providers: [WatchProvider]) -> some View {
        LazyVGrid(columns: [GridItem(), GridItem(), GridItem(), GridItem()]) {
            ForEach(providers, id: \.name) { provider in
                AsyncImage(url: provider.iconUrl, content: { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                }, placeholder: {
                    Rectangle().fill(.thinMaterial)
                })
                .cornerRadius(8)
            }
        }
    }
}

private struct MovieCollectionView: View {

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

                        MoviePreviewView(details: movieDetails) {
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
                    ZStack(alignment: .bottomLeading) {
                        AsyncImage(url: artistDetails.imagePreviewUrl, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }, placeholder: {
                            Color
                                .gray
                                .opacity(0.2)
                        })
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                        VStack(alignment: .leading) {
                            if let character = artistDetails.character {
                                Text(character).font(.caption).bold()
                            }
                            Text(artistDetails.name).font(.caption2)
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 4).foregroundStyle(.ultraThinMaterial))
                        .padding(4)
                    }
                    .onTapGesture(perform: { onArtistSelected(artistDetails.id) })
                }
            }
        }
    }
}

#if DEBUG
struct MovieContentView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            MovieContentViewPreview()
                .environmentObject(Watchlist(items: []))
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
                    movie: movie,
                    onVideoSelected: { _ in }
                )
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = MovieWebService(requestManager: requestManager)
            movie = try! await webService.fetchMovie(with: 353081)
        }
    }
}
#endif
