//
//  TMDBArtistDetailsResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBArtistDetailsResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case biography = "biography"
        case popularity = "popularity"
        case character = "character"
        case birthday = "birthday"
        case deathday = "deathday"
        case imagePath = "profile_path"
    }

    let artistDetails: ArtistDetails

    // MARK: Object life cycle

    init(artistDetails: ArtistDetails) {
        self.artistDetails = artistDetails
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(ArtistDetails.ID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let biography = try container.decodeIfPresent(String.self, forKey: .biography)
        let character = try container.decodeIfPresent(String.self, forKey: .character)
        let popularity = try container.decodeIfPresent(Float.self, forKey: .popularity) ?? 0

        var birthday: Date?
        if let birthdayString = try container.decodeIfPresent(String.self, forKey: .birthday) {
            birthday = TheMovieDbFactory.dateFormatter.date(from: birthdayString)
        }

        var deathday: Date?
        if let deathdayString = try container.decodeIfPresent(String.self, forKey: .deathday) {
            deathday = TheMovieDbFactory.dateFormatter.date(from: deathdayString)
        }

        let imagePath = try container.decode(String.self, forKey: .imagePath)
        let imagePreviewUrl = try TheMovieDbImageRequestFactory.makeURL(format: .avatar(path: imagePath, size: .preview))
        let imageOriginalUrl = try TheMovieDbImageRequestFactory.makeURL(format: .avatar(path: imagePath, size: .original))

        self.artistDetails = ArtistDetails(id: id,
                                           name: name,
                                           birthday: birthday,
                                           deathday: deathday,
                                           imagePreviewUrl: imagePreviewUrl,
                                           imageOriginalUrl: imageOriginalUrl,
                                           biography: biography,
                                           character: character,
                                           popularity: popularity)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(artistDetails.id, forKey: .id)
        try container.encode(artistDetails.name, forKey: .name)
        try container.encodeIfPresent(artistDetails.birthday, forKey: .birthday)
        try container.encodeIfPresent(artistDetails.deathday, forKey: .deathday)
        try container.encode(artistDetails.imagePreviewUrl.lastPathComponent, forKey: .imagePath)
        try container.encodeIfPresent(artistDetails.biography, forKey: .biography)
        try container.encodeIfPresent(artistDetails.character, forKey: .character)
        try container.encodeIfPresent(artistDetails.popularity, forKey: .popularity)
    }
}
