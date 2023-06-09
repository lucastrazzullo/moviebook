//
//  MovieWebService.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation
import MoviebookCommons

struct MovieWebService {

    let requestManager: RequestManager

    // MARK: - Movie

    func fetchMovie(with identifier: Movie.ID) async throws -> Movie {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(identifier)", queryItems: [
            URLQueryItem(name: "append_to_response", value: "credits,videos")
        ])
        let data = try await requestManager.request(from: url)
        var movie = try JSONDecoder().decode(TMDBMovieResponse.self, from: data).result

        if let collectionIdentifier = movie.collection?.id {
            movie.collection = try? await fetchCollection(with: collectionIdentifier)
        }

        if let watchProviders = try? await fetchWatchProviders(with: identifier) {
            movie.watch = watchProviders
        }

        return movie
    }

    private func fetchCollection(with identifier: MovieCollection.ID) async throws -> MovieCollection {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "collection/\(identifier)")
        let data = try await requestManager.request(from: url)
        return try JSONDecoder().decode(TMDBMovieCollectionResponse.self, from: data).result
    }

    private func fetchWatchProviders(with movieIdentifier: Movie.ID) async throws -> WatchProviders {
        let url = try TheMovieDbDataRequestFactory.makeURL(path: "movie/\(movieIdentifier)/watch/providers")
        let data = try await requestManager.request(from: url)
        let results = try JSONDecoder().decode(TheMovieDbResponseWithDictionaryResults<TMDBWatchProviderCollectionResponse>.self, from: data).results.map { key, value in (key, value.result) }
        return WatchProviders(collections: Dictionary(uniqueKeysWithValues: results))
    }

    // MARK: - Movie lists

    func fetchPopular(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/popular", page: page)
    }

    func fetchUpcoming(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/upcoming", page: page)
    }

    func fetchTopRated(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/top_rated", page: page)
    }

    func fetchNowPlaying(page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        return try await fetchMovies(path: "movie/now_playing", page: page)
    }

    private func fetchMovies(path: String, page: Int?) async throws -> (results: [MovieDetails], nextPage: Int?) {
        var queryItems = [URLQueryItem]()
        if let page {
            queryItems.append(URLQueryItem(name: "page", value: String(page)))
        }
        let url = try TheMovieDbDataRequestFactory.makeURL(path: path, queryItems: queryItems)
        let data = try await requestManager.request(from: url)
        let response = try JSONDecoder().decode(TMDBResponseWithListResults<TMDBMovieDetailsResponse>.self, from: data)

        return (results: response.results.map(\.result), nextPage: response.nextPage)
    }
}

// MARK: Response

struct TMDBMovieResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case genres = "genres"
        case collection = "belongs_to_collection"
        case credits = "credits"
    }

    enum CreditsCodingKeys: String, CodingKey {
        case cast = "cast"
    }

    let result: Movie

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(Movie.ID.self, forKey: .id)
        let details = try TMDBMovieDetailsResponse(from: decoder).result
        let genres = try values.decode([TMDBMovieGenreResponse].self, forKey: .genres).map(\.result)
        let production = try TMDBMovieProductionResponse(from: decoder).result
        let watch = WatchProviders(collections: [:])
        let collection = try values.decodeIfPresent(TMDBMovieCollectionResponse.self, forKey: .collection)?.result

        let creditsContainer = try values.nestedContainer(keyedBy: CreditsCodingKeys.self, forKey: .credits)
        let cast = try creditsContainer.decode([TMDBSafeItemResponse<TMDBArtistDetailsResponse>].self, forKey: .cast).compactMap(\.value).map(\.result)

        self.result = Movie(id: id,
                            details: details,
                            genres: genres,
                            cast: cast,
                            production: production,
                            watch: watch,
                            collection: collection)
    }
}

struct TMDBMovieDetailsResponse: Decodable {

    enum Error: Swift.Error {
        case invalidDate
    }

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

    let result: MovieDetails

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(MovieDetails.ID.self, forKey: .id)
        let title = try values.decode(String.self, forKey: .title)
        let overview = try values.decodeIfPresent(String.self, forKey: .overview)
        let rating = Rating(value: try values.decode(Float.self, forKey: .rating), quota: 10.0)
        let media = try TMDBMovieMediaResponse(from: decoder).result

        let releaseDateString = try values.decode(String.self, forKey: .releaseDate)
        guard let releaseDate = TheMovieDbResponse.dateFormatter.date(from: releaseDateString) else {
            throw Error.invalidDate
        }

        let minutes = try values.decodeIfPresent(Int.self, forKey: .runtime)
        var runtime: TimeInterval?
        if let minutes = minutes {
            runtime = TimeInterval(minutes*60)
        }

        let currency = Locale.current.currency?.identifier ?? "EUR"
        var budget: MoneyValue?
        if let budgetValue = try values.decodeIfPresent(Int.self, forKey: .budget) {
            budget = MoneyValue(value: budgetValue, currencyCode: currency)
        }

        var revenue: MoneyValue?
        if let revenueValue = try values.decodeIfPresent(Int.self, forKey: .revenue) {
            revenue = MoneyValue(value: revenueValue, currencyCode: currency)
        }

        self.result = MovieDetails(id: id,
                                   title: title,
                                   release: releaseDate,
                                   runtime: runtime,
                                   overview: overview,
                                   budget: budget,
                                   revenue: revenue,
                                   rating: rating,
                                   media: media)
    }
}

struct TMDBMovieGenreResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
    }

    let result: MovieGenre

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(MovieGenre.ID.self, forKey: .id)
        let name = try values.decode(String.self, forKey: .name)

        self.result = MovieGenre(id: id, name: name)
    }
}

struct TMDBMovieProductionResponse: Decodable {

    struct Company: Decodable {
        let name: String
    }

    enum CodingKeys: String, CodingKey {
        case production = "production_companies"
    }

    let result: MovieProduction

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let companies = try values.decode([Company].self, forKey: .production).map(\.name)

        self.result = MovieProduction(companies: companies)
    }
}

struct TMDBMovieCollectionResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case list = "parts"
    }

    let result: MovieCollection

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let id = try values.decode(MovieCollection.ID.self, forKey: .id)
        let name = try values.decode(String.self, forKey: .name)
        let list = try values.decodeIfPresent([TMDBSafeItemResponse<TMDBMovieDetailsResponse>].self, forKey: .list)?
            .compactMap(\.value)
            .map(\.result) ?? []

        self.result = MovieCollection(id: id, name: name, list: list)
    }
}

struct TMDBMovieMediaResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case videos = "videos"
        case title = "title"
    }

    let result: MovieMedia

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        var posterUrl: URL?
        var posterPreviewUrl: URL?
        if let posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath) {
            posterUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .original))
            posterPreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .preview))
        }

        var backdropUrl: URL?
        var backdropPreviewUrl: URL?
        if let backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath) {
            backdropUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .original))
            backdropPreviewUrl = try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .preview))
        }

        var videos: [MovieVideo] = []
        if let videoResults = try? container.decodeIfPresent(TMDBResponseWithListResults<TMDBMovieVideoResponse>.self, forKey: .videos)?.results {
            videos = videoResults.map(\.result)
        } else {
            videos = []
        }

        self.result = MovieMedia(posterUrl: posterUrl,
                                 posterPreviewUrl: posterPreviewUrl,
                                 backdropUrl: backdropUrl,
                                 backdropPreviewUrl: backdropPreviewUrl,
                                 videos: videos)
    }
}

struct TMDBMovieVideoResponse: Decodable {

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

    let result: MovieVideo

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let official = try values.decode(Bool.self, forKey: .official)
        guard official else {
            throw DecodingError.nonOfficialTrailer
        }

        let id = try values.decode(String.self, forKey: .id)
        let name = try values.decode(String.self, forKey: .name)

        let typeString = try values.decode(String.self, forKey: .type)
        let type: MovieVideo.MediaType
        switch typeString {
        case "Trailer":
            type = .trailer
        case "Teaser":
            type = .teaser
        case "Behind the Scenes":
            type = .behindTheScenes
        default:
            throw DecodingError.typeNotSupported(typeString)
        }

        let key = try values.decode(String.self, forKey: .key)
        let site = try values.decode(String.self, forKey: .site)
        let source: MovieVideo.Source
        switch site {
        case "YouTube":
            source = .youtube(id: key)
        default:
            throw DecodingError.siteNotSupported(site)
        }

        self.result = MovieVideo(id: id, name: name, type: type, source: source)
    }
}

struct TMDBWatchProviderCollectionResponse: Decodable {

    enum CodingKeys: CodingKey {
        case buy
        case rent
        case flatrate
    }

    let result: WatchProviderCollection

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let free = try container.decodeIfPresent([TMDBWatchProviderResponse].self, forKey: .flatrate)?.map(\.result) ?? []
        let rent = try container.decodeIfPresent([TMDBWatchProviderResponse].self, forKey: .rent)?.map(\.result) ?? []
        let buy = try container.decodeIfPresent([TMDBWatchProviderResponse].self, forKey: .buy)?.map(\.result) ?? []

        self.result = WatchProviderCollection(free: free, rent: rent, buy: buy)
    }
}

struct TMDBWatchProviderResponse: Decodable {

    enum CodingKeys: String, CodingKey {
        case name = "provider_name"
        case logoPath = "logo_path"
    }

    let result: WatchProvider

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let name = try container.decode(String.self, forKey: .name)
        let logoPath = try container.decode(String.self, forKey: .logoPath)
        let iconUrl = try TheMovieDbImageRequestFactory.makeURL(format: .logo(path: logoPath, size: .preview))

        self.result = WatchProvider(name: name, iconUrl: iconUrl)
    }
}
