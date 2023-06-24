//
//  MockServer.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import Foundation

public protocol MockServer {
    func data(from url: URL) throws -> Data
}
