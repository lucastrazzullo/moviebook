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
        NavigationView {
            List {
                ForEach(content.sections) { section in
                    SwiftUI.Section(header: Text(section.name)) {
                        ForEach(content.movies[section.id] ?? []) { movie in
                            MoviePreview(details: movie)
                                .onTapGesture {
                                    let watchlistItem = Watchlist.WatchlistItem.movie(id: movie.id)
                                    switch watchlist.itemState(item: watchlistItem) {
                                    case .toWatch:
                                        watchlist.update(state: .watched, for: watchlistItem)
                                    case .watched:
                                        watchlist.update(state: .none, for: watchlistItem)
                                    case .none:
                                        watchlist.update(state: .toWatch, for: watchlistItem)
                                    }
                                }
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listSectionSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
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
                    RoundedRectangle(cornerRadius: 6)
                        .foregroundColor(.gray.opacity(0.2))
                        .frame(width: 80, height: 120)
                        .padding(.trailing, 4)
                        .padding(.bottom, 4)

                    Button(action: {}) {
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
                    }
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

                    if let _ = details.collection {
                        Button(action: {}) {
                            Text("show series")
                            Image(systemName: "chevron.down")
                        }
                        .font(.caption2)
                        .buttonStyle(.borderless)
                        .padding(2)
                        .background(.thinMaterial)
                        .cornerRadius(4)
                        .tint(.primary)
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
    }
}
