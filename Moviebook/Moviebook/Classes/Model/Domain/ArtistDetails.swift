//
//  ArtistDetails.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

struct ArtistDetails: Identifiable, Equatable, Hashable {
    let id: Artist.ID
    let name: String
    let birthday: Date?
    let deathday: Date?
    let imageUrl: URL?
    let biography: String?
}
