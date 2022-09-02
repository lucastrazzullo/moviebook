//
//  FeedView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct FeedView: View {

    @EnvironmentObject private var user: User
    
    var body: some View {
        if user.watchlist.isEmpty {
            DiscoverView()
        } else {
            WatchlistView(watchlist: user.watchlist)
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView().environmentObject(User.mock)
    }
}
