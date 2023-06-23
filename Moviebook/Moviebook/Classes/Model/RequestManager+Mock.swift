//
//  RequestManager+Mock.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 23/06/2023.
//

import Foundation
import MoviebookCommon
import MoviebookTestSupport

#if DEBUG
extension MockRequestManager {

    static let shared: RequestManager = {
        let mockServer = BundleMockServer(bundleIdentifier: "it.lucastrazzullo.ios.TheMovieDb", resourceName: "Mocks")

        return MockRequestManager(server: mockServer)
    }()
}
#endif
