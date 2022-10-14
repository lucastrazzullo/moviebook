//
//  MoviebookView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct MoviebookView: View {

    @EnvironmentObject private var watchlist: Watchlist

    var body: some View {
        WatchlistView()
    }
}

struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
