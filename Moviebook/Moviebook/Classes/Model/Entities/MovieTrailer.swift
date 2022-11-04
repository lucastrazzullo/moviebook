//
//  MovieTrailer.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import Foundation

enum MovieTrailer: Equatable, Identifiable {
    case youtube(id: String)

    var id: String {
        switch self {
        case .youtube(let id):
            return id
        }
    }
}
