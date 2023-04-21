//
//  ExploreListItem.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import Foundation

enum ExploreListItems {
    case movies([MovieDetails])
    case artists([ArtistDetails])
}

//enum ExploreListItem: Hashable {
//    case movie(MovieDetails)
//    case artist(ArtistDetails)
//
//    static func == (lhs: ExploreListItem, rhs: ExploreListItem) -> Bool {
//        switch (lhs, rhs) {
//        case (.movie(let lDetails), .movie(let rDetails)):
//            return lDetails == rDetails
//        case (.artist(let lDetails), .artist(let rDetails)):
//            return lDetails == rDetails
//        default:
//            return false
//        }
//    }
//
//    func hash(into hasher: inout Hasher) {
//        switch self {
//        case .movie(let movieDetails):
//            hasher.combine(movieDetails)
//        case .artist(let artistDetails):
//            hasher.combine(artistDetails)
//        }
//    }
//}
