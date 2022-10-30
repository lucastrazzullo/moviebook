//
//  Response.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

// MARK: - Response with results

struct TheMovieDbResponseWithResults<ItemType: Decodable>: Decodable {
    let results: [ItemType]
}

// MARK: - Entities Decoding Extensions

extension Movie: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case collection = "belongs_to_collection"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(Movie.ID.self, forKey: .id)
        details = try MovieDetails(from: decoder)
        collection = try values.decodeIfPresent(MovieCollection.self, forKey: .collection)
    }
}

extension MovieDetails: Decodable {

    static let releaseDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case overview = "overview"
        case releaseDate = "release_date"
        case runtime = "runtime"
        case rating = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieDetails.ID.self, forKey: .id)
        title = try values.decode(String.self, forKey: .title)
        overview = try values.decodeIfPresent(String.self, forKey: .overview)
        rating = Rating(value: try values.decode(Float.self, forKey: .rating), quota: 10.0)
        media = try MovieMedia(from: decoder)

        let releaseDateString = try values.decodeIfPresent(String.self, forKey: .releaseDate)
        if let releaseDateString = releaseDateString {
            release = Self.releaseDateFormatter.date(from: releaseDateString)
        } else {
            release = nil
        }

        let minutes = try values.decodeIfPresent(Int.self, forKey: .runtime)
        if let minutes = minutes {
            runtime = TimeInterval(minutes*60)
        } else {
            runtime = nil
        }
    }
}

extension MovieCollection: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieCollection.ID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        media = try MovieMedia(from: decoder)
    }
}

extension MovieMedia: Decodable {

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)


        if let posterPath = try values.decodeIfPresent(String.self, forKey: .posterPath) {
            posterUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .original))
            posterPreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .original))
        } else {
            posterUrl = nil
            posterPreviewUrl = nil
        }

        if let backdropPath = try values.decodeIfPresent(String.self, forKey: .backdropPath) {
            backdropUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .original))
            backdropPreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .original))
        } else {
            backdropUrl = nil
            backdropPreviewUrl = nil
        }
    }
}
