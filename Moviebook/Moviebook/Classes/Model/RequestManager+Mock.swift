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
        let bundleIdentifier = "it.lucastrazzullo.ios.TheMovieDb"
        let mockResourceName = "Mocks"
        let mockServer = BundleMockServer(bundleIdentifier: bundleIdentifier, resourceName: mockResourceName)

        return MockRequestManager(server: mockServer)
    }()
}
#endif
