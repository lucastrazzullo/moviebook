//
//  FeedView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct FeedView: View {

    @EnvironmentObject private var watchlist: Watchlist
    
    var body: some View {
        DiscoverView()
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist())
    }
}
