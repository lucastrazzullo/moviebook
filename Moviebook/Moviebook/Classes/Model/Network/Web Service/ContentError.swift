//
//  ContentError.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/11/2022.
//

import Foundation

enum WebServiceError: Error, Equatable {
    case failedToLoad(id: UUID, retry: () -> Void)

    var retry: () -> Void {
        switch self {
        case .failedToLoad(_, let retry):
            return retry
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failedToLoad(let lhsId, _), .failedToLoad(let rhsId, _)):
            return lhsId == rhsId
        }
    }
}
