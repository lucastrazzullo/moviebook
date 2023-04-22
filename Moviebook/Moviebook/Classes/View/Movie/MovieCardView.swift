//
//  MovieCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieCardView: View {

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
                OverviewView(isExpanded: $isOverviewExpanded, overview: overview)
                    .padding(.horizontal)
            }

            if let collection = movie.collection, let list = collection.list, !list.isEmpty {
                CollectionView(
                    name: collection.name,
                    movieDetails: list,
                    highlightedMovieId: movie.id,
                    onMovieIdentifierSelected: { identifier in
                        navigationPath.append(identifier)
                    }
                )
            }

            SpecsView(
                movieDetails: movie.details,
                movieGenres: movie.genres,
                movieProduction: movie.production
            )
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 4, y: -8)
        .animation(.default, value: isOverviewExpanded)
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

private struct OverviewView: View {

    @Binding var isExpanded: Bool

    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.title2)

            Text(overview)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: { isExpanded.toggle() }) {
                Text(isExpanded ? "Less" : "More")
            }
        }
        .padding(.horizontal)
    }
}

private struct CollectionView: View {

    let name: String
    let movieDetails: [MovieDetails]
    let highlightedMovieId: Movie.ID
    let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.title2)
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
                            .frame(width: 80, height: 120)
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
        .background(.ultraThickMaterial)
        .background(.primary)
    }
}

private struct SpecsView: View {

    private static let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()

    let movieDetails: MovieDetails
    let movieGenres: [MovieGenre]
    let movieProduction: MovieProduction

    var body: some View {
        VStack(alignment: .leading) {
            Text("Specs")
                .font(.title2)
                .padding(.leading)

            VStack(alignment: .leading, spacing: 12) {

                if let runtime = movieDetails.runtime, let runtimeString = SpecsView.formatter.string(from: runtime) {
                    SpecsRow(label: "Runtime") {
                        Text(runtimeString)
                    }

                    Divider()
                }

                if let releaseDate = movieDetails.release {
                    SpecsRow(label: "Release date") {
                        Text(releaseDate, style: .date)
                    }

                    Divider()
                }

                if !movieGenres.isEmpty {
                    SpecsRow(label: "Genres") {
                        VStack(alignment: .trailing) {
                            ForEach(movieGenres) { genre in
                                Text(genre.name)
                            }
                        }
                    }

                    Divider()
                }

                SpecsRow(label: "Production") {
                    VStack(alignment: .trailing) {
                        ForEach(movieProduction.companies, id: \.self) { companyName in
                            Text(companyName)
                        }
                    }
                }

                Divider()

                if let budget = movieDetails.budget, budget.value > 0 {
                    SpecsRow(label: "Budget") {
                        VStack(alignment: .trailing) {
                            Text(budget.value, format: .currency(code: budget.currencyCode))
                        }
                    }

                    Divider()
                }

                if let revenue = movieDetails.revenue, revenue.value > 0 {
                    SpecsRow(label: "Incassi") {
                        VStack(alignment: .trailing) {
                            Text(revenue.value, format: .currency(code: revenue.currencyCode))
                        }
                    }
                }
            }
            .font(.subheadline)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(.thinMaterial))
        }
    }
}

private struct SpecsRow<ContentType: View>: View {

    let label: String
    let content: () -> ContentType

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label).bold()
            Spacer()
            content()
        }
    }
}

#if DEBUG
struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            MovieCardView(
                navigationPath: .constant(NavigationPath()),
                movie: MockWebService.movie(with: 954)
            )
            .environmentObject(Watchlist(items: [:]))
        }
    }
}
#endif
