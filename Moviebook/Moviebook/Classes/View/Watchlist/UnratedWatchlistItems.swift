//
//  UnratedWatchlistItems.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 06/08/2023.
//

import SwiftUI
import MoviebookCommon

struct UnratedWatchlistItems: View {

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var watchlist: Watchlist

    @Binding private var navigationPath: NavigationPath
    @State private var presentedItem: NavigationItem?

    let items: [WatchlistViewItem]

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack {
                    ForEach(items, id: \.self) { item in
                        HStack {
                            RemoteImage(url: item.posterUrl, content: { image in
                                image.resizable().aspectRatio(contentMode: .fit)
                            }, placeholder: {
                                Rectangle().fill(.clear)
                            })
                            .frame(width: 80)
                            .cornerRadius(12)
                            .onTapGesture {
                                presentItem(item)
                            }

                            VStack(alignment: .leading) {
                                Text(item.name)
                                    .font(.headline)

                                Text(item.releaseDate, format: .dateTime.year())
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .onTapGesture {
                                presentItem(item)
                            }

                            Spacer()

                            Button { presentItem(.watchlistAddRating(itemIdentifier: item.watchlistIdentifier)) } label: {
                                Text("Add rating")
                            }
                            .buttonStyle(OvalButtonStyle(.prominentTiny))
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Unrated")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: dismiss.callAsFunction) {
                        Text(NSLocalizedString("NAVIGATION.ACTION.DONE", comment: ""))
                    }
                }
            }
        }
        .sheet(item: $presentedItem) { item in
            Navigation(rootItem: item)
        }
    }

    // MARK: Obejct life cycle

    init(items: [WatchlistViewItem], navigationPath: Binding<NavigationPath>) {
        self.items = items
        self._navigationPath = navigationPath
    }

    // MARK: Private methods

    private func presentItem(_ item: WatchlistViewItem) {
        switch item {
        case .movie(let watchlistViewMovieItem, _):
            presentItem(.movieWithIdentifier(watchlistViewMovieItem.details.id))
        }
    }

    private func presentItem(_ item: NavigationItem) {
        switch item {
        case .explore, .movieWithIdentifier, .artistWithIdentifier:
            navigationPath.append(item)
        case .watchlistAddToWatchReason, .watchlistAddRating, .unratedItems:
            presentedItem = item
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct UnratedWatchlistItems_Previews: PreviewProvider {
    static var previews: some View {
        UnratedWatchlistItemsPreview()
            .environmentObject(MockWatchlistProvider().watchlist(configuration: .watchedItems(withSuggestion: false, withRating: false)))
            .environment(\.requestLoader, MockRequestLoader.shared)
    }
}

private struct UnratedWatchlistItemsPreview: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var watchlist: Watchlist

    @State var items: [WatchlistViewItem] = []

    var body: some View {
        UnratedWatchlistItems(items: items, navigationPath: .constant(NavigationPath()))
            .task {
                do {
                    items = try await withThrowingTaskGroup(of: WatchlistViewItem.self) { group in
                        var result = [WatchlistViewItem]()

                        for item in watchlist.items {
                            group.addTask {
                                switch item.id {
                                case .movie(let id):
                                    let movie = try await WebService.movieWebService(requestLoader: requestLoader).fetchMovie(with: id)
                                    let movieItem = WatchlistViewMovieItem(movie: movie)
                                    return WatchlistViewItem.movie(movieItem, watchlistItem: item)
                                }
                            }
                        }

                        for try await item in group {
                            result.append(item)
                        }

                        return result
                    }
                } catch {}
            }
    }
}
#endif
