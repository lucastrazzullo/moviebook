//
//  ArtistWebService.swift
//  MoviebookCommons
//
//  Created by Luca Strazzullo on 11/06/2023.
//

import Foundation

public protocol ArtistWebService {
    func fetchArtist(with identifier: Artist.ID) async throws -> Artist
}
