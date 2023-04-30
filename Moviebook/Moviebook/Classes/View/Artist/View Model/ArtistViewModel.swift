//
//  ArtistViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/04/2023.
//

import Foundation

@MainActor final class ArtistViewModel: ObservableObject {

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
