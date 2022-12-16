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

#if DEBUG
struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [
                .movie(id: 954): .toWatch(reason: .toImplement),
                .movie(id: 616037): .toWatch(reason: .toImplement)
            ]))
    }
}
#endif
