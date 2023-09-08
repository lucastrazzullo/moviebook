//
//  SearchViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation
import Combine
import CoreSpotlight
import MoviebookCommon

@MainActor final class SearchViewModel: ObservableObject {

    @Published var searchScope: SearchDataProvider.Scope = .movie
    @Published var searchKeyword: String

    let content: ExploreContentViewModel

    private var subscriptions: Set<AnyCancellable> = []

    init(scope: SearchDataProvider.Scope, query: String) {
        self.searchScope = scope
        self.searchKeyword = query

        let defaultItems: ExploreContentItems = {
            switch scope {
            case .movie:
                return .movies([])
            case .artist:
                return .artists([])
            }
        }()
        let dataProvider = SearchDataProvider(searchScope: scope, searchKeyword: query)
        self.content = ExploreContentViewModel(
            dataProvider: dataProvider,
            title: "Search",
            subtitle: nil,
            items: defaultItems
        )
    }

    func start(requestLoader: RequestLoader) {
        Publishers.CombineLatest($searchKeyword, $searchScope)
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self, weak requestLoader] keyword, scope in
                guard let self, let requestLoader else { return }

                Task {
                    await self.content.fetch(requestLoader: requestLoader) { dataProvider in
                        if let search = dataProvider as? SearchDataProvider {
                            search.searchKeyword = keyword
                            search.searchScope = scope
                        }
                    }
                }
            })
            .store(in: &subscriptions)
    }
}
