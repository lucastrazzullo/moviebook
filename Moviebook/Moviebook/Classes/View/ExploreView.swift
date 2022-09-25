//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import Combine

@MainActor private final class Content: ObservableObject {

    // MARK: Types

    enum Section: Identifiable, CaseIterable {
        case popular
        case upcoming

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

    @Published var isSearching: Bool = false
    @Published var searchKeyword: String = ""
    @Published var searchResults: [MovieDetails] = []
    @Published var explore: [Section.ID: [MovieDetails]] = [:]

    var sections: [Section] {
        return Section.allCases
    }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Instance methods

    func start(requestManager: RequestManager) async {
        do {
            explore[Section.upcoming.id] = try await UpcomingWebService(requestManager: requestManager).fetch()
            explore[Section.popular.id] = try await PopularWebService(requestManager: requestManager).fetch()
        } catch {
            assertionFailure(error.localizedDescription)
        }

        $searchKeyword
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { keyword in
                Task { [weak self] in
                    self?.isSearching = true
                    let results = try await SearchWebService(requestManager: requestManager).fetchMovie(with: keyword)
                    self?.searchResults = results
                    self?.isSearching = false
                }
            })
            .store(in: &subscriptions)
    }
}

struct ExploreView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist
    @StateObject private var content: Content = Content()

    var body: some View {
        NavigationStack {
            List {
                if !content.searchKeyword.isEmpty {
                    Section(header: HStack(spacing: 4) {
                        Text("\(NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "")): \(content.searchKeyword)")
                        if content.isSearching {
                            ProgressView()
                        }
                    }) {
                        ForEach(content.searchResults) { movie in
                            NavigationLink(value: movie.id) {
                                MoviePreview(details: movie)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }

                ForEach(content.sections) { section in
                    Section(header: Text(section.name)) {
                        ForEach(content.explore[section.id] ?? []) { movie in
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
            .searchable(text: $content.searchKeyword)
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

    let details: MovieDetails

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: imageUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .frame(width: 160, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
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

            WatchlistButton(watchlistItem: Watchlist.WatchlistItem.movie(id: details.id))
                .font(.caption)
        }
        .contextMenu {
            WatchlistMenu(watchlistItem: Watchlist.WatchlistItem.movie(id: details.id))
        }
    }

    var imageUrl: URL? {
        guard let path = details.backdropPath else {
            return nil
        }
        return try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: path, size: .thumb))
    }
}

private struct WatchlistMenu: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        switch watchlist.itemState(item: watchlistItem) {
        case .toWatch:
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "eye")
            }
        case .watched:
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Move to watchlist", systemImage: "star")
            }
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
        case .none:
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "eye")
            }
        }
    }
}

private struct WatchlistButton: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        HStack {
            switch watchlist.itemState(item: watchlistItem) {
            case .toWatch:
                Image(systemName: "star")
            case .watched:
                Image(systemName: "eye")
            case .none:
                Image(systemName: "plus")
            }
        }
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
        .onTapGesture {
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
