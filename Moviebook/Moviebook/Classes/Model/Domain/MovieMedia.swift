//
//  MovieMedia.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import Foundation

struct MovieMedia: Equatable, Hashable {
    let posterUrl: URL?
    let posterPreviewUrl: URL?
    let backdropUrl: URL?
    let backdropPreviewUrl: URL?

    let videos: [MovieVideo]
}
