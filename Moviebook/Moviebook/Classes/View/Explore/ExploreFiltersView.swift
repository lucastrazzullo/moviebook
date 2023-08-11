//
//  ExploreFiltersView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/08/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreFiltersView: View {

    enum Filter: String, CaseIterable, MenuSelectorItem {
        case genres
        case release

        var label: String {
            return self.rawValue
        }
    }

    @State private var filterSelection: Filter = .genres

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
                items: Filter.allCases
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
