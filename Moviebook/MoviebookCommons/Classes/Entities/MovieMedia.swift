//
//  MovieMedia.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import Foundation

public struct MovieMedia: Equatable, Hashable {
    public let posterUrl: URL?
    public let posterPreviewUrl: URL?
    public let posterThumbnailUrl: URL?

    public let backdropUrl: URL?
    public let backdropPreviewUrl: URL?

    public let videos: [MovieVideo]

    public init(posterUrl: URL?,
                posterPreviewUrl: URL?,
                posterThumbnailUrl: URL?,
                backdropUrl: URL?,
                backdropPreviewUrl: URL?,
                videos: [MovieVideo]) {
        self.posterUrl = posterUrl
        self.posterPreviewUrl = posterPreviewUrl
        self.posterThumbnailUrl = posterThumbnailUrl
        self.backdropUrl = backdropUrl
        self.backdropPreviewUrl = backdropPreviewUrl
        self.videos = videos
    }
}
