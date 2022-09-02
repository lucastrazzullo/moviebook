//
//  MoviebookApp.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

@main
struct MoviebookApp: App {

    let user = User.shared

    var body: some Scene {
        WindowGroup {
            FeedView().environmentObject(user)
        }
    }
}
