//
//  MoviebookView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI

struct MoviebookView: View {

    var body: some View {
        WatchlistView()
    }
}

#if DEBUG
struct MoviebookView_Previews: PreviewProvider {
    static var previews: some View {
        MoviebookView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(inMemoryItems: [
                .movie(id: 954): .toWatch(reason: .none),
                .movie(id: 616037): .toWatch(reason: .none)
            ]))
    }
}
#endif
