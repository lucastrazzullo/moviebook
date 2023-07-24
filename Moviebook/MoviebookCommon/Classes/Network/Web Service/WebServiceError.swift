//
//  WebServiceError.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 11/11/2022.
//

import Foundation

public enum WebServiceError: Error, Equatable, Identifiable {
    case failedToLoad(error: Error, retry: () -> Void)

    public var id: String {
        return underlyingError.localizedDescription
    }

    public var underlyingError: Error {
        switch self {
        case .failedToLoad(let error, _):
            return error
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
        case (.failedToLoad(let lhsError, _), .failedToLoad(let rhsError, _)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        }
    }
}
