//
//  ArtistDetails.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

struct ArtistDetails: Identifiable, Equatable, Hashable {
    var id: Artist.ID
    var name: String
    var imageUrl: URL?
}
