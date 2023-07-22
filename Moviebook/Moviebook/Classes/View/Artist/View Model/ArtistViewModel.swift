//
//  ArtistViewModel.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 30/04/2023.
//

import Foundation
import MoviebookCommon

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
        self.setArtist(artist)
    }

    // MARK: Instance methods

    func start(requestLoader: RequestLoader) {
        guard artist == nil else { return }
        loadArtist(requestLoader: requestLoader)
    }

    private func loadArtist(requestLoader: RequestLoader) {
        Task {
            do {
                setArtist(try await WebService.artistWebService(requestLoader: requestLoader).fetchArtist(with: artistId))
            } catch {
                self.error = .failedToLoad(id: .init(), retry: { [weak self, weak requestLoader] in
                    if let requestLoader {
                        self?.loadArtist(requestLoader: requestLoader)
                    }
                })
            }
        }
    }

    private func setArtist(_ artist: Artist) {
        self.artist = artist
        Spotlight.index(artist: artist)
    }
}
