//
//  ExploreView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import Combine

@MainActor private final class SearchContent: ObservableObject {

    // MARK: Instance Properties

    var title: String {
        return NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "") + ": " + searchKeyword
    }

    @Published var searchKeyword: String = ""
    @Published var movies: [MovieDetails] = []
    @Published var isLoading: Bool = false
    @Published var error: WebServiceError? = nil

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Search

    func start(requestManager: RequestManager) {
        $searchKeyword
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self, weak requestManager] keyword in
                if let requestManager {
                    self?.fetchMovies(for: keyword, requestManager: requestManager)
                }
            })
            .store(in: &subscriptions)
    }

    private func fetchMovies(for keyword: String, requestManager: RequestManager) {
        Task {
            do {
                error = nil
                isLoading = true
                movies = try await SearchWebService(requestManager: requestManager).fetchMovie(with: keyword)
                isLoading = false
            } catch {
                self.isLoading = false
                self.error = .failedToLoad(id: .init()) { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.fetchMovies(for: keyword, requestManager: requestManager)
                    }
                }
            }
        }
    }
}

@MainActor private final class ExploreContent: ObservableObject {

    // MARK: Types

    enum Section: String, Identifiable, CaseIterable {
        case popular
        case upcoming

        var id: String {
            return rawValue
        }
    }

    final class SectionContent: ObservableObject, Identifiable {

        private let section: Section

        var id: Section.ID {
            return section.id
        }

        var name: String {
            switch section {
            case .upcoming:
                return NSLocalizedString("MOVIE.UPCOMING", comment: "")
            case .popular:
                return NSLocalizedString("MOVIE.POPULAR", comment: "")
            }
        }

        @Published var movies: [MovieDetails] = []
        @Published var error: WebServiceError? = nil
        @Published var isLoading: Bool = false

        init(section: Section) {
            self.section = section
        }

        func fetch(requestManager: RequestManager) {
            Task {
                do {
                    error = nil
                    isLoading = true
                    movies = try await fetchMovies(requestManager: requestManager)
                    isLoading = false
                } catch {
                    self.isLoading = false
                    self.error = .failedToLoad(id: .init()) { [weak self, weak requestManager] in
                        if let requestManager {
                            self?.fetch(requestManager: requestManager)
                        }
                    }
                }
            }
        }

        private func fetchMovies(requestManager: RequestManager) async throws -> [MovieDetails] {
            switch section {
            case .popular:
                return try await PopularWebService(requestManager: requestManager).fetch()
            case .upcoming:
                return try await UpcomingWebService(requestManager: requestManager).fetch()
            }
        }
    }

    // MARK: Instance Properties

    @Published var sections: [SectionContent] = Section.allCases.map { SectionContent(section: $0) }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        for section in sections {
            section.fetch(requestManager: requestManager)
            section.objectWillChange
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.objectWillChange.send()
                }
                .store(in: &subscriptions)
        }
    }
}

struct ExploreView: View {

    private struct MovieIdentifier: Identifiable {
        let id: Movie.ID
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var searchContent: SearchContent = SearchContent()
    @StateObject private var exploreContent: ExploreContent = ExploreContent()

    @State private var movieNavigationPath: NavigationPath = NavigationPath()
    @State private var presentedMovieIdentifier: MovieIdentifier?

    var body: some View {
        NavigationView {
            List {
                if searchContent.isLoading || !searchContent.searchKeyword.isEmpty {
                    SectionView(title: searchContent.title,
                                isLoading: searchContent.isLoading,
                                error: searchContent.error,
                                movies: searchContent.movies,
                                onMovieSelected: { movieIdentifier in
                        presentedMovieIdentifier = MovieIdentifier(id: movieIdentifier)
                    })
                }

                ForEach(exploreContent.sections) { section in
                    SectionView(title: section.name,
                                isLoading: section.isLoading,
                                error: section.error,
                                movies: section.movies,
                                onMovieSelected: { movieIdentifier in
                        presentedMovieIdentifier = MovieIdentifier(id: movieIdentifier)
                    })
                }
                .listSectionSeparator(.hidden)
            }
            .listStyle(.inset)
            .navigationTitle(NSLocalizedString("EXPLORE.TITLE", comment: ""))
            .toolbar {
                ToolbarItem {
                    Button(action: dismiss.callAsFunction) {
                        Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                    }
                }
            }
            .searchable(
                text: $searchContent.searchKeyword,
                prompt: NSLocalizedString("EXPLORE.SEARCH.PROMPT", comment: "")
            )
            .sheet(item: $presentedMovieIdentifier) { movieIdentifier in
                NavigationStack(path: $movieNavigationPath) {
                    MovieView(movieId: movieIdentifier.id, navigationPath: $movieNavigationPath)
                        .navigationDestination(for: Movie.ID.self) { movieId in
                            MovieView(movieId: movieId, navigationPath: $movieNavigationPath)
                        }
                }
            }
            .onAppear {
                searchContent.start(requestManager: requestManager)
                exploreContent.start(requestManager: requestManager)
            }
        }
    }
}

private struct SectionView: View {

    let title: String
    let isLoading: Bool
    let error: WebServiceError?
    let movies: [MovieDetails]
    let onMovieSelected: (Movie.ID) -> Void

    var body: some View {
        Section(header: header) {
            ForEach(movies) { movieDetails in
                MoviePreviewView(details: movieDetails) {
                    onMovieSelected(movieDetails.id)
                }
            }
        }
        .listSectionSeparator(.hidden)
    }

    private var header: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .foregroundColor(.primary)

            if isLoading {
                ProgressView()
            }
            if let error = error {
                HStack {
                    Spacer()
                    Text("Something went wrong")
                        .foregroundColor(.primary)
                        .underline()

                    Button(action: error.retry) {
                        Text("Retry")
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

#if DEBUG
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreView()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    .movie(id: 954): .toWatch(reason: .none),
                    .movie(id: 616037): .toWatch(reason: .none)
                ]))
        }
    }
}
#endif
