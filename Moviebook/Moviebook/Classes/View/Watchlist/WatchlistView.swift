//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct WatchlistView: View {

    enum PresentedItem: Identifiable {
        case explore
        case movie(Movie)

        var id: AnyHashable {
            switch self {
            case .explore:
                return "Explore"
            case .movie(let movie):
                return movie.id
            }
        }
    }

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var content: WatchlistViewContent = WatchlistViewContent()

    @State private var presentedItemNavigationPath = NavigationPath()
    @State private var presentedItem: PresentedItem? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(content.items) { item in
                    switch item {
                    case .movie(let movie, _):
                        MoviePreviewView(details: movie.details) {
                            presentedItem = .movie(movie)
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Section", selection: $content.currentSection) {
                        ForEach(content.sectionIdentifiers, id: \.self) { section in
                            if let name = content.sections[section]?.name {
                                Text(name)
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                    .onAppear {
                        UISegmentedControl.appearance().backgroundColor = UIColor(Color.black.opacity(0.8))
                        UISegmentedControl.appearance().selectedSegmentTintColor = .white
                        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
                        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    WatermarkView {
                        Image(systemName: "magnifyingglass")
                            .onTapGesture {
                                presentedItem = .explore
                            }
                    }
                }
            }
            .sheet(item: $presentedItem) { item in
                NavigationStack(path: $presentedItemNavigationPath) {
                    Group {
                        switch item {
                        case .explore:
                            ExploreView()
                        case .movie(let movie):
                            MovieView(movie: movie, navigationPath: $presentedItemNavigationPath)
                        }
                    }
                    .navigationDestination(for: NavigationItem.self) { item in
                        NavigationDestination(navigationPath: $presentedItemNavigationPath, item: item)
                    }
                }
            }
            .onAppear {
                content.start(watchlist: watchlist, requestManager: requestManager)
            }
        }
    }
}

private struct EmptyWatchlistView: View {

    var onStartDiscoverySelected: () -> Void

    var body: some View {
        VStack {
            Text("Your watchlist is empty")
                .font(.headline)

            Button(action: onStartDiscoverySelected) {
                Label("Start your discovery", systemImage: "rectangle.and.text.magnifyingglass")
            }.buttonStyle(.borderedProminent)
        }
    }
}

#if DEBUG
struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(inMemoryItems: [
                .movie(id: 954): .toWatch(reason: .none),
                .movie(id: 616037): .toWatch(reason: .none)
            ]))
    }
}
#endif
