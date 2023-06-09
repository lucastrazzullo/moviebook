//
//  MovieVideo.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import Foundation

public struct MovieVideo: Equatable, Hashable, Identifiable {

    public enum Source: Equatable, Hashable {
        case youtube(id: String)
    }

    public enum MediaType: Hashable {
        case teaser
        case trailer
        case behindTheScenes
    }

    public let id: String
    public let name: String
    public let type: MediaType
    public let source: Source

    public init(id: String, name: String, type: MediaType, source: Source) {
        self.id = id
        self.name = name
        self.type = type
        self.source = source
    }
}
