//
//  ArtistWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import Foundation
import MoviebookCommons

struct ArtistWebService {

    let requestManager: RequestManager

    func fetchArtist(with identifier: Artist.ID) async throws -> Artist {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "person/\(identifier)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits")
        ])
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBArtistResponse.self, from: data).result
    }
}

// MARK: Response

struct TMDBArtistResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case credits = "credits"
    }

    enum CreditsCodingKeys: String, CodingKey {
        case cast
    }

    let result: Artist

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(Movie.ID.self, forKey: .id)
        let details = try TMDBArtistDetailsResponse(from: decoder).result

        let creditsContainer = try values.nestedContainer(keyedBy: CreditsCodingKeys.self, forKey: .credits)
        let filmography = try creditsContainer.decodeIfPresent([TMDBSafeItemResponse<TMDBMovieDetailsResponse>].self, forKey: .cast)?
            .compactMap(\.value)
            .map(\.result) ?? []

        self.result = Artist(id: id, details: details, filmography: filmography)
    }
}

struct TMDBArtistDetailsResponse: Decodable {

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

    let result: ArtistDetails

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let id = try container.decode(ArtistDetails.ID.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let biography = try container.decodeIfPresent(String.self, forKey: .biography)
        let character = try container.decodeIfPresent(String.self, forKey: .character)
        let popularity = try container.decodeIfPresent(Float.self, forKey: .popularity) ?? 0

        var birthday: Date?
        if let birthdayString = try container.decodeIfPresent(String.self, forKey: .birthday) {
            birthday = TheMovieDbResponse.dateFormatter.date(from: birthdayString)
        }

        var deathday: Date?
        if let deathdayString = try container.decodeIfPresent(String.self, forKey: .deathday) {
            deathday = TheMovieDbResponse.dateFormatter.date(from: deathdayString)
        }

        let imagePath = try container.decode(String.self, forKey: .imagePath)
        let imagePreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .avatar(path: imagePath, size: .preview))
        let imageOriginalUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .avatar(path: imagePath, size: .original))

        self.result = ArtistDetails(id: id,
                                    name: name,
                                    birthday: birthday,
                                    deathday: deathday,
                                    imagePreviewUrl: imagePreviewUrl,
                                    imageOriginalUrl: imageOriginalUrl,
                                    biography: biography,
                                    character: character,
                                    popularity: popularity)
    }
}
