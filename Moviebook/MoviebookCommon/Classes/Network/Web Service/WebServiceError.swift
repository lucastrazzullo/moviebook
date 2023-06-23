//
//  WebServiceError.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/11/2022.
//

import Foundation

public enum WebServiceError: Error, Equatable, Identifiable {
    case failedToLoad(id: UUID, retry: () -> Void)

    public var id: UUID {
        switch self {
        case .failedToLoad(let id, _):
            return id
        }
    }

    public var retry: () -> Void {
        switch self {
        case .failedToLoad(_, let retry):
            return retry
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.failedToLoad(let lhsId, _), .failedToLoad(let rhsId, _)):
            return lhsId == rhsId
        }
    }
}
