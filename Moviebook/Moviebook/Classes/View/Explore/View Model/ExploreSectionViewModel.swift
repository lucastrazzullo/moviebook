//
//  ExploreSectionViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine

@MainActor final class ExploreSectionViewModel: ObservableObject {

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

        @Published var items: [MovieDetails] = []
        @Published var isLoading: Bool = false
        @Published var error: WebServiceError? = nil
        @Published var fetchNextPage: (() -> Void)?

        init(section: Section) {
            self.section = section
        }

        func fetch(requestManager: RequestManager, page: Int? = nil) {
            Task {
                do {
                    isLoading = true
                    error = nil
                    fetchNextPage = nil

                    let result = try await fetchMovies(requestManager: requestManager, page: page)
                    if let nextPage = result.nextPage {
                        fetchNextPage = { [weak self] in self?.fetch(requestManager: requestManager, page: nextPage) }
                    }

                    items = items + result.results
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

        private func fetchMovies(requestManager: RequestManager, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
            switch section {
            case .popular:
                return try await PopularWebService(requestManager: requestManager).fetch(page: page)
            case .upcoming:
                return try await UpcomingWebService(requestManager: requestManager).fetch(page: page)
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
