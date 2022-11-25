//
//  MovieVideo.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import Foundation

struct MovieVideo: Equatable, Identifiable {

    enum Source: Equatable {
        case youtube(id: String)
    }

    enum MediaType {
        case teaser
        case trailer
        case behindTheScenes
    }

    let id: String
    let name: String
    let type: MediaType
    let source: Source
}
