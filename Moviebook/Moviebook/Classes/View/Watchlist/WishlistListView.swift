//
//  WishlistListView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 24/07/2023.
//

import SwiftUI
import MoviebookCommon

struct WishlistListView: View {

    @AppStorage("wishlistSorting") private var internalSorting: WatchlistViewSorting = .lastAdded
    @State private var isPresented: Bool = false
    @State private var selectedGenre: MovieGenre? = nil

    @Binding var sorting: WatchlistViewSorting

    let items: [WatchlistViewItem]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        VStack(spacing: 24) {
            MovieGenresPicker(
                selectedGenre: $selectedGenre,
                genres: allGenres
            )

            ListView(
                items: items,
                sorting: sorting,
                genreFilter: selectedGenre,
                onItemSelected: onItemSelected
            )
        }
        .onAppear {
            isPresented = true
            sorting = internalSorting
        }
        .onDisappear {
            isPresented = false
        }
        .onChange(of: sorting) { sorting in
            if isPresented {
                internalSorting = sorting
            }
        }
        .animation(.default, value: selectedGenre)
    }

    private var allGenres: [MovieGenre] {
        let uniqueGenres = items.reduce(Set<MovieGenre>()) { list, item in
            switch item {
            case .movie(let movie, _):
                return list.union(Set(movie.genres))
            }
        }

        return Array(uniqueGenres).sorted(by: { $0.name < $1.name })
    }
}

private struct ListView: View {

    struct ListSection: Hashable {
        let collection: MovieCollection?
        var items: [WatchlistViewItem]
    }

    let sections: [ListSection]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(spacing: 4), GridItem()], spacing: 4) {
            ForEach(sections, id: \.self) { section in
                Section(header: sectionHeader(section: section), footer: sectionFooter(section: section)) {
                    ForEach(section.items) { item in
                        switch item {
                        case .movie(let movie, _):
                            MovieShelfPreviewView(
                                movieDetails: movie.details,
                                onItemSelected: onItemSelected
                            )
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: Object life cycle

    init(items: [WatchlistViewItem], sorting: WatchlistViewSorting, genreFilter: MovieGenre?, onItemSelected: @escaping (NavigationItem) -> Void) {
        self.sections = Self.makeSections(items: items, sorting: sorting, genreFilter: genreFilter)
        self.onItemSelected = onItemSelected
    }

    // MARK: Private view builders

    @ViewBuilder private func sectionHeader(section: ListSection) -> some View {
        if let collection = section.collection {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: "square.grid.2x2")
                Text(collection.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
    }

    @ViewBuilder private func sectionFooter(section: ListSection) -> some View {
        if let collection = section.collection {
            MovieCollectionFooterView(
                collection: collection,
                moviesFilter: Set(section.items.compactMap { item in
                    if case .movie(let movie, _) = item {
                        return movie.id
                    } else {
                        return nil
                    }
                }),
                onItemSelected: onItemSelected
            )
            .padding(.bottom)
        } else {
            Spacer()
        }
    }

    // MARK: Private factory methods

    private static func makeSections(items: [WatchlistViewItem], sorting: WatchlistViewSorting, genreFilter: MovieGenre?) -> [ListSection] {

        var sections: [ListSection] = []
        var currentSection: ListSection?

        for item in items
            .filter(filter(genre: genreFilter))
            .sorted(by: sort(sorting: sorting)) {
            switch item {
            case .movie(let movie, _):
                if let collection = movie.collection {
                    if let index = sections.firstIndex(where: { $0.collection?.id == collection.id }) {
                        sections[index].items.append(item)
                    } else if let collectionId = currentSection?.collection?.id, collectionId == movie.collection?.id {
                        currentSection?.items.append(item)
                    } else {
                        if let currentSection {
                            sections.append(currentSection)
                        }

                        currentSection = ListSection(
                            collection: collection,
                            items: [item]
                        )
                    }
                } else {
                    if currentSection?.collection?.id != nil {
                        sections.append(currentSection!)
                        currentSection = nil
                    }

                    if currentSection != nil {
                        currentSection?.items.append(item)
                    } else {
                        currentSection = ListSection(
                            collection: nil,
                            items: [item]
                        )
                    }
                }
            }
        }

        if let currentSection {
            sections.append(currentSection)
        }

        return sections
    }

    private static func filter(genre: MovieGenre?) -> (WatchlistViewItem) -> Bool {
        return { item in
            guard let genre else {
                return true
            }
            switch item {
            case .movie(let movie, _):
                return Set(movie.genres).contains(genre)
            }
        }
    }

    private static func sort(sorting: WatchlistViewSorting) -> (WatchlistViewItem, WatchlistViewItem) -> Bool {
        return { lhs, rhs in
            switch sorting {
            case .lastAdded:
                return lhs.addedDate > rhs.addedDate
            case .rating:
                return lhs.rating > rhs.rating
            case .name:
                return lhs.name < rhs.name
            case .release:
                return lhs.releaseDate > rhs.releaseDate
            }
        }
    }
}

private struct MovieCollectionFooterView: View {

    @Environment(\.requestLoader) var requestManager

    @State private var movies: [MovieDetails] = []

    let collection: MovieCollection
    let moviesFilter: Set<Movie.ID>
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ZStack {
            if !movies.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "plus.square")
                        Text("More from collection")
                    }
                    .font(.footnote.bold())

                    LazyVGrid(columns: [GridItem(spacing: 4),
                                        GridItem(spacing: 4),
                                        GridItem(spacing: 4),
                                        GridItem(spacing: 4)], spacing: 4) {

                        ForEach(movies) { movie in
                            MovieShelfPreviewView(
                                movieDetails: movie,
                                onItemSelected: onItemSelected
                            )
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
        .task {
            let webService = WebService.movieWebService(requestLoader: requestManager)
            movies = (try? await webService.fetchMovieCollection(with: collection.id))?.list?.filter({ !moviesFilter.contains($0.id) }) ?? []
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct WishlistListView_Previews: PreviewProvider {
    static let requestLoader = MockRequestLoader.shared
    static let watchlist = MockWatchlistProvider.shared.watchlist(configuration: .toWatchItems(withSuggestion: false))
    static var previews: some View {
        ScrollView {
            WishlistListViewPreviewView()
        }
        .environment(\.requestLoader, requestLoader)
        .environmentObject(watchlist)
    }
}

@MainActor private final class ViewModel: ObservableObject {

    @Published var items: [WatchlistViewItem] = []

    func start(watchlist: Watchlist, requestLoader: RequestLoader) async {
        let content = WatchlistViewSectionContent(section: .toWatch)
        try? await content.updateItems(watchlist.items, requestLoader: requestLoader)
        items = content.items
    }
}

private struct WishlistListViewPreviewView: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @StateObject var viewModel = ViewModel()

    var body: some View {
        WishlistListView(
            sorting: .constant(.lastAdded),
            items: viewModel.items,
            onItemSelected: { _ in }
        )
        .task {
            await viewModel.start(
                watchlist: watchlist,
                requestLoader: requestLoader
            )
        }
    }
}
#endif
