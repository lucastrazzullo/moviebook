//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@MainActor private final class Content: ObservableObject {

    // MARK: Types

    enum Section: Identifiable, CaseIterable {
        case upcoming
        case popular

        var id: String {
            return self.name
        }

        var name: String {
            switch self {
            case .upcoming:
                return NSLocalizedString("MOVIE.UPCOMING", comment: "")
            case .popular:
                return NSLocalizedString("MOVIE.POPULAR", comment: "")
            }
        }
    }

    // MARK: Instance Properties

    @Published var movies: [Section.ID: [MovieDetails]] = [:]

    var sections: [Section] {
        return Section.allCases
    }

    // MARK: Instance methods

    func start(requestManager: RequestManager) async {
        do {
            movies[Section.upcoming.id] = try await UpcomingWebService(requestManager: requestManager).fetch()
            movies[Section.popular.id] = try await PopularWebService(requestManager: requestManager).fetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }
    }
}

struct ExploreView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist
    @StateObject private var content: Content = Content()

    var body: some View {
        NavigationStack {
            List {
                ForEach(content.sections) { section in
                    SwiftUI.Section(header: Text(section.name)) {
                        ForEach(content.movies[section.id] ?? []) { movie in
                            NavigationLink(value: movie.id) {
                                MoviePreview(details: movie)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
            .navigationDestination(for: Movie.ID.self) { movieId in
                MovieView(movieId: movieId)
            }
            .task {
                await content.start(requestManager: requestManager)
            }
        }
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist())
    }
}

// MARK: - Private Views

private struct MoviePreview: View {

    @EnvironmentObject var watchlist: Watchlist

    let details: MovieDetails

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: makePosterUrl(path: details.posterPath), content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(width: 80, height: 120)
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)

                    Button(
                        action: {
                            let watchlistItem = Watchlist.WatchlistItem.movie(id: details.id)
                            switch watchlist.itemState(item: watchlistItem) {
                            case .toWatch:
                                watchlist.update(state: .watched, for: watchlistItem)
                            case .watched:
                                watchlist.update(state: .none, for: watchlistItem)
                            case .none:
                                watchlist.update(state: .toWatch, for: watchlistItem)
                            }
                        },
                        label: {
                            HStack {
                                let watchlistItem = Watchlist.WatchlistItem.movie(id: details.id)
                                switch watchlist.itemState(item: watchlistItem) {
                                case .toWatch:
                                    Image(systemName: "star")
                                case .watched:
                                    Image(systemName: "eye")
                                case .none:
                                    Image(systemName: "plus")
                                }
                            }
                            .frame(width: 12, height: 12)
                        }
                    )
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(details.title)
                        .lineLimit(3)
                        .font(.subheadline)
                        .frame(maxWidth: 140, alignment: .leading)

                    Text("10.10.2018")
                        .font(.caption)

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { rating in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
    }

    private func makePosterUrl(path: String?) -> URL? {
        guard let path = path else {
            return nil
        }

        return try? TheMovieDbImageRequestFactory.makeURL(path: path, format: .poster(size: .thumb))
    }
}
