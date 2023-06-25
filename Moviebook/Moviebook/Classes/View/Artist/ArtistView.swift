//
//  ArtistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI
import MoviebookCommon

struct ArtistView: View {

    @Environment(\.requestManager) var requestManager

    @Binding private var navigationPath: NavigationPath

    @StateObject private var viewModel: ArtistViewModel
    @State private var isErrorPresented: Bool = false

    var body: some View {
        Group {
            if let artist = viewModel.artist {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: artist.details.name,
                    posterUrl: artist.details.imageOriginalUrl,
                    trailingHeaderView: {
                        ArtistTrailingHeaderView(artistDetails: artist.details)
                    }, content: {
                        ArtistContentView(navigationPath: $navigationPath, artist: artist)
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
        .onChange(of: viewModel.error) { error in
            isErrorPresented = error != nil
        }
        .onAppear {
            viewModel.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(artistId: Artist.ID, navigationPath: Binding<NavigationPath>) {
        self._viewModel = StateObject(wrappedValue: ArtistViewModel(artistId: artistId))
        self._navigationPath = navigationPath
    }
}

private struct ArtistTrailingHeaderView: View {

    let artistDetails: ArtistDetails

    var body: some View {
        WatermarkView {
            ShareButton(deeplink: Deeplink.artist(identifier: artistDetails.id),
                        previewTitle: artistDetails.name,
                        previewImageUrl: artistDetails.imagePreviewUrl)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ArtistView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ArtistView(artistId: 287, navigationPath: .constant(NavigationPath()))
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 353081), state: .toWatch(info: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "This is really nice"))))
                ]))
        }
    }
}
#endif
