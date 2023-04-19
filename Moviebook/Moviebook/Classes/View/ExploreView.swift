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
                    Task {
                        await self?.fetchMovies(for: keyword, requestManager: requestManager)
                    }
                }
            })
            .store(in: &subscriptions)
    }

    private func fetchMovies(for keyword: String, requestManager: RequestManager) async {
        do {
            isLoading = true
            movies = try await SearchWebService(requestManager: requestManager).fetchMovie(with: keyword)
            isLoading = false
        } catch {
            self.error = .failedToLoad(id: .init()) { [weak self] in
                Task {
                    await self?.fetchMovies(for: keyword, requestManager: requestManager)
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

    @Published var data: [Section: [MovieDetails]] = [:]
    @Published var error: WebServiceError? = nil

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        for section in Section.allCases {
            Task {
                await fetchMovies(in: section, requestManager: requestManager)
            }
        }
    }

    // MARK: Data

    private func fetchMovies(in section: Section, requestManager: RequestManager) async {
        do {
            switch section {
            case .popular:
                data[section] = try await PopularWebService(requestManager: requestManager).fetch()
            case .upcoming:
                data[section] = try await UpcomingWebService(requestManager: requestManager).fetch()
            }
        } catch {
            self.error = .failedToLoad(id: .init()) { [weak self] in
                Task {
                    await self?.fetchMovies(in: section, requestManager: requestManager)
                }
            }
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
    @State private var isMoviePresented: MovieIdentifier?

    var body: some View {
        NavigationView {
            List {
                if searchContent.isLoading || !searchContent.movies.isEmpty {
                    Section(header: HStack(spacing: 4) {
                        Text(searchContent.title)
                        if searchContent.isLoading {
                            ProgressView()
                        }
                    }) {
                        ForEach(searchContent.movies) { movieDetails in
                            MoviePreviewView(details: movieDetails) {
                                isMoviePresented = MovieIdentifier(id: movieDetails.id)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }

                ForEach(ExploreContent.Section.allCases) { section in
                    if let movies = exploreContent.data[section], !movies.isEmpty {
                        Section(header: Text(section.name)) {
                            ForEach(movies) { movieDetails in
                                MoviePreviewView(details: movieDetails) {
                                    isMoviePresented = MovieIdentifier(id: movieDetails.id)
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
            .sheet(item: $isMoviePresented) { movieIdentifier in
                NavigationStack(path: $movieNavigationPath) {
                    MovieView(movieId: movieIdentifier.id, navigationPath: $movieNavigationPath)
                        .navigationDestination(for: Movie.ID.self) { movieId in
                            MovieView(movieId: movieId, navigationPath: $movieNavigationPath)
                        }
                }
            }
            .alert(item: $exploreContent.error) { error in
                Alert(title: Text("Error"), dismissButton: .destructive(Text("Retry")) {
                    error.retry()
                })
            }
            .onAppear {
                searchContent.start(requestManager: requestManager)
                exploreContent.start(requestManager: requestManager)
            }
        }
    }
}

#if DEBUG
struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                .movie(id: 954): .toWatch(reason: .none),
                .movie(id: 616037): .toWatch(reason: .none)
            ]))
    }
}
#endif
