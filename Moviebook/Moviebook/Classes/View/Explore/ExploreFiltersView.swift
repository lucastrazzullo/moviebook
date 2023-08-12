//
//  ExploreFiltersView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/08/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreFiltersView: View {

    enum Filter: MenuSelectorItem {
        case genres(count: Int)
        case release(isSelected: Bool)

        var id: String {
            return label
        }

        var badge: Int {
            switch self {
            case .genres(let count):
                return count
            case .release(let isSelected):
                return isSelected ? 1 : 0
            }
        }

        var label: String {
            switch self {
            case .genres:
                return "Genres"
            case .release:
                return "Release year"
            }
        }
    }

    @State private var filterSelection: Filter = .genres(count: 0)

    @ObservedObject var viewModel: ExploreFiltersViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Filters")
                .font(.heroHeadline)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            MenuSelector(
                selection: $filterSelection,
                items: filterItems
            )
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch filterSelection {
            case .genres:
                MovieGenreSelectionView(
                    selectedGenres: $viewModel.selectedGenres,
                    genres: viewModel.genres
                )
            case .release:
                MovieYearSelectionView(
                    selection: $viewModel.selectedYear,
                    years: viewModel.years
                )
            }
        }
    }

    private var filterItems: [Filter] {
        return [
            .genres(count: viewModel.selectedGenres.count),
            .release(isSelected: viewModel.selectedYear != nil)
        ]
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreFilters_Previews: PreviewProvider {
    static var viewModel = ExploreFiltersViewModel(selectedGenres: [])
    static var previews: some View {
        ScrollView {
            ExploreFiltersView(viewModel: viewModel)
                .onAppear {
                    viewModel.start(requestLoader: MockRequestLoader.shared)
                }
        }
    }
}
#endif
