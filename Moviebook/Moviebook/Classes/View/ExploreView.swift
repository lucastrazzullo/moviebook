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
    @Published var error: WebServiceError?

    var sections: [Section] {
        return Section.allCases
    }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        loadMovies(for: .upcoming, requestManager: requestManager)
        loadMovies(for: .popular, requestManager: requestManager)

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

    private func loadMovies(for section: Section, requestManager: RequestManager) {
        Task {
            do {
                switch section {
                case .popular:
                    explore[section.id] = try await PopularWebService(requestManager: requestManager).fetch()
                case .upcoming:
                    explore[section.id] = try await UpcomingWebService(requestManager: requestManager).fetch()
                }

            } catch {
                self.error = .failedToLoad(id: .init(), retry: { [weak self] in
                    self?.loadMovies(for: section, requestManager: requestManager)
                })
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

    @StateObject private var content: Content = Content()
    @State private var movieNavigationPath: NavigationPath = NavigationPath()
    @State private var isMoviePresented: MovieIdentifier?
    @State private var isErrorPresented: Bool = false

    var body: some View {
        NavigationView {
            List {
                if !content.searchKeyword.isEmpty {
                    Section(header: HStack(spacing: 4) {
                        Text("\(NSLocalizedString("EXPLORE.SEARCH.RESULTS", comment: "")): \(content.searchKeyword)")
                        if content.isSearching {
                            ProgressView()
                        }
                    }) {
                        ForEach(content.searchResults) { movieDetails in
                            MoviePreviewView(details: movieDetails) {
                                isMoviePresented = MovieIdentifier(id: movieDetails.id)
                            }
                        }
                    }
                    .listRowSeparator(.hidden)
                    .listSectionSeparator(.hidden)
                }

                ForEach(content.sections) { section in
                    Section(header: Text(section.name)) {
                        ForEach(content.explore[section.id] ?? []) { movieDetails in
                            MoviePreviewView(details: movieDetails) {
                                isMoviePresented = MovieIdentifier(id: movieDetails.id)
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
                text: $content.searchKeyword,
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
            .alert("Error", isPresented: $isErrorPresented) {
                Button("Retry", role: .cancel) {
                    content.error?.retry()
                }
            }
            .onChange(of: content.error) { error in
                isErrorPresented = error != nil
            }
            .onAppear {
                content.start(requestManager: requestManager)
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
                .movie(id: 954): .toWatch(reason: .toImplement),
                .movie(id: 616037): .toWatch(reason: .toImplement)
            ]))
    }
}
#endif
