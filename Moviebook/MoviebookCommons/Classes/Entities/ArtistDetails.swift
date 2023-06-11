//
//  ArtistDetails.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

public struct ArtistDetails: Identifiable, Equatable, Hashable {
    public let id: Artist.ID
    public let name: String
    public let birthday: Date?
    public let deathday: Date?
    public let imagePreviewUrl: URL?
    public let imageOriginalUrl: URL?
    public let biography: String?
    public let character: String?
    public let popularity: Float

    public init(id: Artist.ID, name: String, birthday: Date?, deathday: Date?, imagePreviewUrl: URL?, imageOriginalUrl: URL?, biography: String?, character: String?, popularity: Float) {
        self.id = id
        self.name = name
        self.birthday = birthday
        self.deathday = deathday
        self.imagePreviewUrl = imagePreviewUrl
        self.imageOriginalUrl = imageOriginalUrl
        self.biography = biography
        self.character = character
        self.popularity = popularity
    }
}
