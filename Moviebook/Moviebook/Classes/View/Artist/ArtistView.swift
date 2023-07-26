//
//  ArtistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI
import MoviebookCommon

struct ArtistView: View {

    @Environment(\.requestLoader) var requestLoader

    @StateObject private var viewModel: ArtistViewModel

    @Binding private var navigationPath: NavigationPath
    @State private var presentedItem: NavigationItem?

    @State private var isErrorPresented: Bool = false

    var body: some View {
        Group {
            if let artist = viewModel.artist {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: artist.details.name,
                    posterUrl: artist.details.imageOriginalUrl,
                    trailingHeaderView: { _ in
                        ShareButton(artistDetails: artist.details)
                    }, content: {
                        ArtistContentView(
                            artist: artist,
                            onItemSelected: presentItem
                        )
                    }
                )
            } else {
                LoaderView()
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .toolbar(.hidden, for: .navigationBar)
        .alert("Error", isPresented: $isErrorPresented) {
            Button("Retry", role: .cancel) {
                viewModel.error?.retry()
            }
        }
        .sheet(item: $presentedItem) { item in
            Navigation(rootItem: item)
        }
        .onChange(of: viewModel.error) { error in
            isErrorPresented = error != nil
        }
        .onAppear {
            viewModel.start(requestLoader: requestLoader)
        }
    }

    // MARK: Obejct life cycle

    init(artistId: Artist.ID, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: ArtistViewModel(artistId: artistId))
        self._navigationPath = navigationPath
    }

    // MARK: Private methods

    private func presentItem(_ item: NavigationItem) {
        switch item {
        case .explore, .movieWithIdentifier, .artistWithIdentifier:
            navigationPath.append(item)
        case .watchlistAddToWatchReason, .watchlistAddRating:
            presentedItem = item
        }
    }
}

private struct ShareButton: View {

    let artistDetails: ArtistDetails

    var body: some View {
        ShareLink(item: Deeplink.artist(identifier: artistDetails.id).rawValue) {
            Image(systemName: "square.and.arrow.up")
                .frame(width: 18, height: 18, alignment: .center)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ArtistView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ArtistView(artistId: 287, navigationPath: .constant(NavigationPath()))
                .environmentObject(MockWatchlistProvider.shared.watchlist())
                .environment(\.requestLoader, MockRequestLoader.shared)
        }
    }
}
#endif
