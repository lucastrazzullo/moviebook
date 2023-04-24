//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import Combine

@MainActor private final class Content: ObservableObject {

    // MARK: Types

    enum Section: Identifiable, Hashable, CaseIterable {
        case toWatch
        case watched

        var id: String {
            return self.name
        }

        var name: String {
            switch self {
            case .toWatch:
                return NSLocalizedString("WATCHLIST.TO_WATCH.TITLE", comment: "")
            case .watched:
                return NSLocalizedString("WATCHLIST.WATCHED.TITLE", comment: "")
            }
        }
    }

    enum Item: Identifiable {
        case movie(id: Movie.ID, movie: Movie?)

        var id: Movie.ID {
            switch self {
            case .movie(let id, _):
                return id
            }
        }
    }

    // MARK: Instance Properties

    @Published var items: [Content.Section: [Item]] = [:]
    @Published var error: WebServiceError?

    var sections: [Section] {
        return Section.allCases
    }

    private var subscriptions: Set<AnyCancellable> = []

    // MARK: Object life cycle

    init() {
        sections.forEach { section in
            items[section] = []
        }
    }

    // MARK: Internal methods

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        subscriptions.forEach({ $0.cancel() })

        watchlist.$content
            .map(\.items)
            .sink { [weak self, requestManager] items in
                self?.update(watchlistItems: items, requestManager: requestManager)
            }
            .store(in: &subscriptions)
    }

    func items(for section: Content.Section) -> [Item] {
        return items[section] ?? []
    }

    // MARK: Private helper methods

    private func section(for watchlistState: Moviebook.WatchlistContent.ItemState) -> Content.Section? {
        switch watchlistState {
        case .toWatch:
            return .toWatch
        case .watched:
            return .watched
        default:
            return nil
        }
    }

    private func update(watchlistItems: [Moviebook.WatchlistContent.Item: Moviebook.WatchlistContent.ItemState], requestManager: RequestManager) {
        watchlistItems.forEach { itemTuple in
            let watchlistItemState = itemTuple.value
            let watchlistItem = itemTuple.key

            guard let itemSection = section(for: watchlistItemState) else {
                return
            }

            switch watchlistItem {
            case .movie(let id):
                switchOrAdd(movieWith: id, toSection: itemSection, requestManager: requestManager)
            }
        }
    }

    private func switchOrAdd(movieWith id: Movie.ID, toSection: Content.Section, requestManager: RequestManager) {
        sections.forEach { section in
            if section == toSection {
                guard !items(for: section).contains(where: { $0.id == id }) else {
                    return
                }

                items[section]?.append(.movie(id: id, movie: nil))
                load(movieWith: id, in: section, requestManager: requestManager)
            } else {
                guard let index = items(for: section).firstIndex(where: { $0.id == id }) else {
                    return
                }

                items[section]?.remove(at: index)
            }
        }
    }

    private func load(movieWith id: Movie.ID, in section: Content.Section, requestManager: RequestManager) {
        let webService = MovieWebService(requestManager: requestManager)
        Task {
            do {
                if let index = items[section]?.firstIndex(where: { $0.id == id }) {
                    let movie = try await webService.fetchMovie(with: id)
                    items[section]?.remove(at: index)
                    items[section]?.insert(.movie(id: id, movie: movie), at: index)
                }
            } catch {
                print("FAILED movie with id: \(id)", error)
            }
        }
    }
}

struct WatchlistView: View {

    enum PresentedItem: Identifiable {
        case movie(Movie)

        var id: AnyHashable {
            switch self {
            case .movie(let movie):
                return movie.id
            }
        }
    }

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist
    @StateObject private var content: Content = Content()

    @State private var presentedItemNavigationPath = NavigationPath()

    @State private var selectedSection: Content.Section = .toWatch
    @State private var isExplorePresented: Bool = false
    @State private var isItemPresented: PresentedItem? = nil
    @State private var isErrorPresented: Bool = false

    var body: some View {
        NavigationView {
            List {
                ForEach(content.items(for: selectedSection)) { item in
                    switch item {
                    case .movie(_, let movie):
                        MoviePreviewView(details: movie?.details) {
                            if let movie = movie {
                                isItemPresented = .movie(movie)
                            }
                        }
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .navigationTitle(NSLocalizedString("WATCHLIST.TITLE", comment: ""))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Picker("Section", selection: $selectedSection) {
                        ForEach(content.sections, id: \.self) { section in
                            Text(section.name)
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
                                isExplorePresented = true
                            }
                    }
                }
            }
            .sheet(isPresented: $isExplorePresented) {
                ExploreView()
            }
            .sheet(item: $isItemPresented) { item in
                NavigationStack(path: $presentedItemNavigationPath) {
                    Group {
                        switch item {
                        case .movie(let movie):
                            MovieView(movie: movie, navigationPath: $presentedItemNavigationPath)
                        }
                    }
                    .navigationDestination(for: NavigationItem.self) { item in
                        NavigationDestination(navigationPath: $presentedItemNavigationPath, item: item)
                    }
                }
            }
            .alert("Error", isPresented: $isErrorPresented) {
                Button("Retry", role: .cancel) {
                    content.error?.retry()
                }
            }
            .onChange(of: content.error) { error in
                isErrorPresented = error != nil
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
            .environmentObject(Watchlist(items: [
                .movie(id: 954): .toWatch(reason: .none),
                .movie(id: 616037): .toWatch(reason: .none)
            ]))
    }
}
#endif
