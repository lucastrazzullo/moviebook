//
//  MovieCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieCardView: View {

    @State private var isOverviewExpanded: Bool = false

    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            MovieHeaderView(details: movie.details)

            MovieWatchlistStateView(
                movieId: movie.id,
                movieBackdropPreviewUrl: movie.details.media.backdropPreviewUrl
            )

            if let overview = movie.details.overview, !overview.isEmpty {
                MovieOverviewView(isExpanded: $isOverviewExpanded, overview: overview)
            }

            MovieSpecsView(
                movieDetails: movie.details,
                movieGenres: movie.genres,
                movieProduction: movie.production
            )
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 4, y: -8)
        .animation(.default, value: isOverviewExpanded)
    }
}

private struct MovieHeaderView: View {

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

private struct MovieWatchlistStateView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieId: Movie.ID
    let movieBackdropPreviewUrl: URL?

    var body: some View {
        Group {
            switch watchlist.itemState(item: .movie(id: movieId)) {
            case .none:
                VStack(alignment: .leading, spacing: 8) {
                    Text("You haven't watched this movie.")
                        .font(.headline)

                    Text("If you add it to your watchlist, you can also add a note or you can mark it as watched and add your own vote.")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing)

                    Spacer()

                    HStack {
                        Button(action: { watchlist.update(state: .toWatch, for: .movie(id: movieId)) }) {
                            WatchlistLabel(itemState: .none)
                        }
                        .buttonStyle(.borderedProminent)

                        Button(action: { watchlist.update(state: .watched, for: .movie(id: movieId)) }) {
                            WatchlistLabel(itemState: .watched)
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                }

            case .toWatch:
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening").font(.title)
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested by Valerio.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("This movie is amazing. Great special effects.")
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.body)
                        }
                        Button(action: { watchlist.update(state: .watched, for: .movie(id: movieId)) }) {
                            WatchlistIcon(itemState: .watched)
                            Text("Mark as watched")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }

            case .watched:
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top, spacing: 8) {
                        CircularRatingView(rating: 2.5, label: "Your vote", style: .prominent)
                        .frame(height: 150)

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("You watched this movie")
                                .font(.headline)
                                .multilineTextAlignment(.trailing)

                            WatermarkWatchlistButton(watchlistItem: .movie(id: movieId))
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial.opacity(0.6))
                    .background(Color.accentColor.opacity(0.2))
                    .background(ZStack {
                        AsyncImage(
                            url: movieBackdropPreviewUrl,
                            content: { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            },
                            placeholder: { Color.black }
                        )
                        .opacity(0.4)
                    })
                    .background(Color.black)
                    .cornerRadius(12)

                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening").font(.title)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested by Valerio.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("This movie is amazing. Great special effects.")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 8).stroke(.orange))
    }
}

private struct MovieOverviewView: View {

    @Binding var isExpanded: Bool

    let overview: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Overview")
                .font(.title2)

            Text(overview)
                .font(.body)
                .lineLimit(isExpanded ? nil : 3)

            Button(action: { isExpanded.toggle() }) {
                Text(isExpanded ? "Less" : "More")
            }
        }
        .padding(.horizontal)
    }
}

private struct MovieSpecsView: View {

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
        VStack(alignment: .leading, spacing: 12) {
            Text("Specs")
                .font(.title2)
                .padding(.bottom)

            if let runtime = movieDetails.runtime, let runtimeString = MovieSpecsView.formatter.string(from: runtime) {
                MovieSpecsRow(label: "Runtime") {
                    Text(runtimeString)
                }

                Divider()
            }

            if let releaseDate = movieDetails.release {
                MovieSpecsRow(label: "Release date") {
                    Text(releaseDate, style: .date)
                }

                Divider()
            }

            if !movieGenres.isEmpty {
                MovieSpecsRow(label: "Genres") {
                    VStack(alignment: .trailing) {
                        ForEach(movieGenres) { genre in
                            Text(genre.name)
                        }
                    }
                }

                Divider()
            }

            MovieSpecsRow(label: "Production") {
                VStack(alignment: .trailing) {
                    ForEach(movieProduction.companies, id: \.self) { companyName in
                        Text(companyName)
                    }
                }
            }

            Divider()

            if let budget = movieDetails.budget, budget.value > 0 {
                MovieSpecsRow(label: "Budget") {
                    VStack(alignment: .trailing) {
                        Text(budget.value, format: .currency(code: budget.currencyCode))
                    }
                }

                Divider()
            }

            if let revenue = movieDetails.revenue, revenue.value > 0 {
                MovieSpecsRow(label: "Incassi") {
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

private struct MovieSpecsRow<ContentType: View>: View {

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
        ScrollView {
            MovieCardView(movie: MockServer.movie(with: 616037))
                .environmentObject(Watchlist(moviesToWatch: [616037]))
        }
    }
}
#endif
