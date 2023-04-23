//
//  ArtistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI

@MainActor private final class Content: ObservableObject {

    // MARK: Instance Properties

    @Published var artist: Artist?
    @Published var error: WebServiceError?

    private let artistId: Artist.ID

    // MARK: Object life cycle

    init(artistId: Artist.ID) {
        self.artistId = artistId
    }

    init(artist: Artist) {
        self.artistId = artist.id
        self.artist = artist
    }

    // MARK: Instance methods

    func start(requestManager: RequestManager) {
        guard artist == nil else { return }
        loadArtist(requestManager: requestManager)
    }

    private func loadArtist(requestManager: RequestManager) {
        Task {
            do {
                artist = try await ArtistWebService(requestManager: requestManager).fetchArtist(with: artistId)
            } catch {
                self.error = .failedToLoad(id: .init(), retry: { [weak self, weak requestManager] in
                    if let requestManager {
                        self?.loadArtist(requestManager: requestManager)
                    }
                })
            }
        }
    }
}

struct ArtistView: View {

    @Environment(\.requestManager) var requestManager

    @Binding private var navigationPath: NavigationPath

    @StateObject private var content: Content
    @State private var isErrorPresented: Bool = false

    var body: some View {
        Group {
            if let artist = content.artist {
                SlidingCardView(
                    navigationPath: $navigationPath,
                    title: artist.details.name,
                    posterUrl: artist.details.imageOriginalUrl,
                    trailingHeaderView: {
                        EmptyView()
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
                content.error?.retry()
            }
        }
        .onChange(of: content.error) { error in
            isErrorPresented = error != nil
        }
        .onAppear {
            content.start(requestManager: requestManager)
        }
    }

    // MARK: Obejct life cycle

    init(artistId: Artist.ID, navigationPath: Binding<NavigationPath>) {
        self._content = StateObject(wrappedValue: Content(artistId: artistId))
        self._navigationPath = navigationPath
    }
}

#if DEBUG
struct ArtistView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistView(artistId: 287, navigationPath: .constant(NavigationPath()))
            .environment(\.requestManager, MockRequestManager())
    }
}
#endif
