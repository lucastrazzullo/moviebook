//
//  ExploreViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine

@MainActor final class ExploreViewModel: ObservableObject {

    // MARK: Types

    enum List: String, Identifiable, CaseIterable {
        case nowPlaying
        case upcoming
        case popular
        case topRated

        var id: String {
            return rawValue
        }

        var name: String {
            switch self {
            case .nowPlaying:
                return NSLocalizedString("MOVIE.NOW_PLAYING", comment: "")
            case .upcoming:
                return NSLocalizedString("MOVIE.UPCOMING", comment: "")
            case .popular:
                return NSLocalizedString("MOVIE.POPULAR", comment: "")
            case .topRated:
                return NSLocalizedString("MOVIE.TOP_RATED", comment: "")
            }
        }

        var fetchResults: ExploreContentViewModel.FetchResults {
            return { requestManager, page in
                switch self {
                case .nowPlaying:
                    return try await MovieWebService(requestManager: requestManager).fetchNowPlaying(page: page)
                case .upcoming:
                    return try await MovieWebService(requestManager: requestManager).fetchUpcoming(page: page)
                case .popular:
                    return try await MovieWebService(requestManager: requestManager).fetchPopular(page: page)
                case .topRated:
                    return try await MovieWebService(requestManager: requestManager).fetchTopRated(page: page)
                }
            }
        }
    }

    // MARK: Instance Properties

    @Published var sections: [ExploreContentViewModel] = List.allCases.map { section in
        ExploreContentViewModel(title: section.name, fetchResults: section.fetchResults)
    }

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
