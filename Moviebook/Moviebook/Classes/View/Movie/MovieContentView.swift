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
        VStack(alignment: .leading, spacing: 30) {
            HeaderView(details: movie.details)
                .padding(.horizontal)

            MovieWatchlistStateView(
                movieId: movie.id,
                movieBackdropPreviewUrl: movie.details.media.backdropPreviewUrl
            )
            .padding(.horizontal)

            if let overview = movie.details.overview, !overview.isEmpty {
                ExpandibleOverviewView(isExpanded: $isOverviewExpanded, overview: overview)
                    .padding(.horizontal)
            }

            if let collection = movie.collection, let list = collection.list, !list.isEmpty {
                MovieCollectionView(
                    title: collection.name,
                    movieDetails: list,
                    highlightedMovieId: movie.id,
                    onMovieIdentifierSelected: { identifier in
                        navigationPath.append(identifier)
                    }
                )
                .background(Color.yellow)
            }

            SpecsView(title: "Specs", items: specs)
                .padding(.horizontal)
        }
        .animation(.default, value: isOverviewExpanded)
    }

    private var specs: [SpecsView.Item] {
        var specs = [SpecsView.Item]()

        if let runtime = movie.details.runtime {
            specs.append(.duration(runtime, label: "Runtime"))
        }

        if let releaseDate = movie.details.release {
            specs.append(.date(releaseDate, label: "Release date"))
        }

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
            if let releaseDate = details.release {
                Text(releaseDate, format: .dateTime.year()).font(.caption)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct MovieCollectionView: View {

    let title: String
    let movieDetails: [MovieDetails]
    let highlightedMovieId: Movie.ID?
    let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.title2)
                .padding()
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Spacer()
                        .frame(width: 0)
                        .padding(.leading)
                        .padding(.leading)

                    ForEach(movieDetails) { movieDetails in
                        Group {
                            AsyncImage(url: movieDetails.media.posterPreviewUrl, content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            }, placeholder: {
                                Color
                                    .gray
                                    .opacity(0.2)
                            })
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(movieDetails.id == highlightedMovieId ? Color.black.opacity(0.6) : Color.clear)
                            )
                        }
                        .onTapGesture {
                            onMovieIdentifierSelected(movieDetails.id)
                        }
                    }

                    Spacer()
                        .frame(width: 0)
                        .padding(.trailing)
                        .padding(.trailing)
                }
                .padding(.bottom)
            }
            .padding(.bottom)
        }
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
