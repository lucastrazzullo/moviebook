//
//  PopularArtistsView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 03/09/2023.
//

import SwiftUI
import MoviebookCommon

struct PopularArtistsView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var popularArtistsViewModel: PopularArtistsViewModel
    @StateObject private var searchVewModel: SearchViewModel

    @Binding private var presentedItem: NavigationItem?
    @State private var isSearching: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            ExploreVerticalSectionView(
                viewModel: isSearching
                    ? searchVewModel.content
                    : popularArtistsViewModel.content,
                onItemSelected: { item in
                    presentedItem = item
                }
            )
        }
        .scrollDismissesKeyboard(.immediately)
        .safeAreaInset(edge: .top) {
            HeaderView(
                viewModel: isSearching
                   ? searchVewModel.content
                   : popularArtistsViewModel.content,
                searchKeyword: $searchVewModel.searchKeyword,
                isSearching: $isSearching
            )
            .padding(.vertical)
            .background(.thinMaterial)
            .overlay(Rectangle().fill(.thinMaterial).frame(height: 1), alignment: .bottom)
        }
        .task {
            popularArtistsViewModel.start(watchlist: watchlist, requestLoader: requestLoader)
            searchVewModel.start(requestLoader: requestLoader)
        }
    }

    init(presentedItem: Binding<NavigationItem?>) {
        _presentedItem = presentedItem
        _popularArtistsViewModel = StateObject(
            wrappedValue: PopularArtistsViewModel()
        )
        _searchVewModel = StateObject(
            wrappedValue: SearchViewModel(scope: .artist, query: "")
        )
    }
}

private struct HeaderView: View {

    let viewModel: ExploreContentViewModel

    @Binding var searchKeyword: String
    @Binding var isSearching: Bool

    @FocusState private var focusedField: Bool

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Text(viewModel.title)
                        .font(.heroHeadline)
                    if let subtitle = viewModel.subtitle {
                        Text(subtitle)
                            .font(.caption)
                    }
                }

                Button(action: { isSearching.toggle() }) {
                    Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                }
                .buttonStyle(OvalButtonStyle(.normal))
                .padding(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if isSearching {
                TextField("Search an artist", text: $searchKeyword)
                    .textFieldStyle(OvalTextFieldStyle())
                    .textContentType(.givenName)
                    .focused($focusedField)
                    .submitLabel(.search)
                    .padding(.horizontal)
                    .onAppear { focusedField = true }
            }
        }
        .animation(.default, value: isSearching)
    }
}

#if DEBUG

import MoviebookTestSupport

struct PopularArtistsView_Previews: PreviewProvider {
    static var previews: some View {
        PopularArtistsView(presentedItem: .constant(nil))
            .environmentObject(MockWatchlistProvider.shared.watchlist())
            .environmentObject(MockFavouritesProvider.shared.favourites())
            .environment(\.requestLoader, MockRequestLoader.shared)
    }
}

#endif
