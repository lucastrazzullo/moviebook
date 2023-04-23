//
//  Response.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

// MARK: - Response with results

struct TheMovieDbResponseWithResults<ItemType: Decodable>: Decodable {

    struct SafeItem<Base: Decodable>: Decodable {
        public let value: Base?

        public init(from decoder: Decoder) throws {
            do {
                let container = try decoder.singleValueContainer()
                self.value = try container.decode(Base.self)
            } catch {
                self.value = nil
            }
        }
    }

    let results: [ItemType]

    enum CodingKeys: CodingKey {
        case results
    }

    init(from decoder: Decoder) throws {
        let container: KeyedDecodingContainer<CodingKeys> = try decoder.container(keyedBy: CodingKeys.self)
        self.results = try container.decode([SafeItem<ItemType>].self, forKey: CodingKeys.results).compactMap({ $0.value })
    }
}

enum TheMovieDbResponse {

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

// MARK: - Entities Decoding Extensions

extension Movie: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case genres = "genres"
        case collection = "belongs_to_collection"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(Movie.ID.self, forKey: .id)
        details = try MovieDetails(from: decoder)
        genres = try values.decode([MovieGenre].self, forKey: .genres)
        production = try MovieProduction(from: decoder)
        collection = try values.decodeIfPresent(MovieCollection.self, forKey: .collection)
    }
}

extension MovieDetails: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case overview = "overview"
        case budget = "budget"
        case revenue = "revenue"
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
            release = TheMovieDbResponse.dateFormatter.date(from: releaseDateString)
        } else {
            release = nil
        }

        let minutes = try values.decodeIfPresent(Int.self, forKey: .runtime)
        if let minutes = minutes {
            runtime = TimeInterval(minutes*60)
        } else {
            runtime = nil
        }

        if let budgetValue = try values.decodeIfPresent(Int.self, forKey: .budget) {
            budget = MoneyValue(value: budgetValue, currencyCode: TheMovieDbConfiguration.currency)
        } else {
            budget = nil
        }

        if let revenueValue = try values.decodeIfPresent(Int.self, forKey: .revenue) {
            revenue = MoneyValue(value: revenueValue, currencyCode: TheMovieDbConfiguration.currency)
        } else {
            revenue = nil
        }
    }
}

extension MovieGenre: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieGenre.ID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
    }
}

extension MovieProduction: Decodable {

    struct Company: Decodable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case production = "production_companies"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        companies = try values.decode([Company].self, forKey: .production).map(\.name)
    }
}

extension MovieCollection: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case list = "parts"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(MovieCollection.ID.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        list = try values.decodeIfPresent([MovieDetails].self, forKey: .list)
    }
}

extension MovieMedia: Decodable {

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case videos = "videos"
        case title = "title"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath) {
            posterUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .original))
            posterPreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .preview))
        } else {
            posterUrl = nil
            posterPreviewUrl = nil
        }

        if let backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath) {
            backdropUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .original))
            backdropPreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .preview))
        } else {
            backdropUrl = nil
            backdropPreviewUrl = nil
        }

        if let videoResults = try? container.decodeIfPresent(TheMovieDbResponseWithResults<MovieVideo>.self, forKey: .videos)?.results {
            videos = videoResults
        } else {
            videos = []
        }
    }
}

extension MovieVideo: Decodable {
    
    enum DecodingError: Error {
        case siteNotSupported(_ site: String)
        case typeNotSupported(_ type: String)
        case nonOfficialTrailer
    }
    
    enum CodingKeys: CodingKey {
        case id
        case name
        case key
        case site
        case type
        case official
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let official = try values.decode(Bool.self, forKey: .official)
        guard official else {
            throw DecodingError.nonOfficialTrailer
        }

        id = try values.decode(String.self, forKey: .id)
        name = try values.decode(String.self, forKey: .name)

        let type = try values.decode(String.self, forKey: .type)
        switch type {
        case "Trailer":
            self.type = .trailer
        case "Teaser":
            self.type = .teaser
        case "Behind the Scenes":
            self.type = .behindTheScenes
        default:
            throw DecodingError.typeNotSupported(type)
        }

        let key = try values.decode(String.self, forKey: .key)
        let site = try values.decode(String.self, forKey: .site)
        switch site {
        case "YouTube":
            self.source = .youtube(id: key)
        default:
            throw DecodingError.siteNotSupported(site)
        }
    }
}

extension Artist: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case credits = "credits"
    }

    enum CreditsCodingKeys: String, CodingKey {
        case cast
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(Movie.ID.self, forKey: .id)
        details = try ArtistDetails(from: decoder)

        let creditsContainer = try values.nestedContainer(keyedBy: CreditsCodingKeys.self, forKey: .credits)
        filmography = try creditsContainer.decodeIfPresent([MovieDetails].self, forKey: .cast) ?? []
    }
}

extension ArtistDetails: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case biography = "biography"
        case birthday = "birthday"
        case deathday = "deathday"
        case imagePath = "profile_path"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(ArtistDetails.ID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        biography = try container.decodeIfPresent(String.self, forKey: .biography)

        if let birthdayString = try container.decodeIfPresent(String.self, forKey: .birthday) {
            birthday = TheMovieDbResponse.dateFormatter.date(from: birthdayString)
        } else {
            birthday = nil
        }

        if let deathdayString = try container.decodeIfPresent(String.self, forKey: .deathday) {
            deathday = TheMovieDbResponse.dateFormatter.date(from: deathdayString)
        } else {
            deathday = nil
        }

        let imagePath = try container.decode(String.self, forKey: .imagePath)
        imagePreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .avatar(path: imagePath, size: .preview))
        imageOriginalUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .avatar(path: imagePath, size: .original))
    }
}
