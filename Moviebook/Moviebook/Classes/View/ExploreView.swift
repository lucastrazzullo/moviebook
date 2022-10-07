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
                                MoviePreviewView(details: movie)
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
                                MoviePreviewView(details: movie)
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
            .searchable(text: $content.searchKeyword, prompt: NSLocalizedString("EXPLORE.SEARCH.PROMPT", comment: ""))
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
            .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
