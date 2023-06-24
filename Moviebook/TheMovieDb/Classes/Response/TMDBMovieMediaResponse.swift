//
//  TMDBMovieMediaResponse.swift
//  TheMovieDb
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon

struct TMDBMovieMediaResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case videos = "videos"
    }

    let result: MovieMedia

    // MARK: Object life cycle

    init(result: MovieMedia) {
        self.result = result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let posterPath = try container.decode(String.self, forKey: .posterPath)
        let posterUrl = try TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .original))
        let posterPreviewUrl = try TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .preview))
        let posterThumbnailUrl = try TheMovieDbImageRequestFactory.makeURL(format: .poster(path: posterPath, size: .thumbnail))

        let backdropPath = try container.decode(String.self, forKey: .backdropPath)
        let backdropUrl = try TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .original))
        let backdropPreviewUrl = try TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: backdropPath, size: .preview))

        var videos: [MovieVideo] = []
        if let videoResults = try? container.decodeIfPresent(TMDBResponseWithListResults<TMDBMovieVideoResponse>.self, forKey: .videos)?.results {
            videos = videoResults.map(\.result)
        } else {
            videos = []
        }

        self.result = MovieMedia(posterUrl: posterUrl,
                                 posterPreviewUrl: posterPreviewUrl,
                                 posterThumbnailUrl: posterThumbnailUrl,
                                 backdropUrl: backdropUrl,
                                 backdropPreviewUrl: backdropPreviewUrl,
                                 videos: videos)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(result.posterUrl.lastPathComponent, forKey: .posterPath)
        try container.encode(result.backdropUrl.lastPathComponent, forKey: .backdropPath)
        try container.encode(result.videos.map(TMDBMovieVideoResponse.init(result:)), forKey: .videos)
    }
}
