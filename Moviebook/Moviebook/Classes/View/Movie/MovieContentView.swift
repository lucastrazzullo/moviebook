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

    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            HeaderView(details: movie.details)

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

            if !specs.isEmpty {
                SpecsView(title: "Specs", items: specs)
            }

            if let collection = movie.collection, let list = collection.list, !list.isEmpty {
                MovieCollectionView(
                    title: "Collection",
                    movies: list,
                    highlightedMovieId: movie.id,
                    onMovieIdentifierSelected: { identifier in
                        navigationPath.append(identifier)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(details.title).font(.title)
            RatingView(rating: details.rating)
            Text(details.release, format: .dateTime.year()).font(.caption)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct MovieCollectionView: View {

    let title: String
    let movies: [MovieDetails]
    let highlightedMovieId: Movie.ID?
    let onMovieIdentifierSelected: (Movie.ID) -> Void

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
                                onMovieIdentifierSelected(movieDetails.id)
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

#if DEBUG
struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            MovieContentView(
                navigationPath: .constant(NavigationPath()),
                movie: MockWebService.movie(with: 954)
            )
            .environmentObject(Watchlist(items: [:]))
        }
    }
}
#endif
