//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct WatchlistView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var viewModel: WatchlistViewModel = WatchlistViewModel()

    let onExploreSelected: () -> Void
    let onMovieSelected: (Movie) -> Void

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                switch item {
                case .movie(let movie, _):
                    MoviePreviewView(details: movie.details) {
                        onMovieSelected(movie)
                    }
                }
            }
            .listRowSeparator(.hidden)
        }
        .scrollIndicators(.hidden)
        .listStyle(.plain)
        .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Picker("Section", selection: $viewModel.currentSection) {
                    ForEach(viewModel.sectionIdentifiers, id: \.self) { section in
                        if let name = viewModel.sections[section]?.name {
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
                            onExploreSelected()
                        }
                }
            }
        }
        .onAppear {
            viewModel.start(watchlist: watchlist, requestManager: requestManager)
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
        NavigationView {
            WatchlistView(onExploreSelected: {}, onMovieSelected: { _ in })
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(suggestion: nil))),
                    WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(suggestion: nil)))
                ]))
        }
    }
}
#endif
