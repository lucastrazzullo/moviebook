//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import CoreData

struct WatchlistView: View {

    @ObservedObject var watchlist: Watchlist

    var body: some View {
        NavigationView {
            List {
                Text("There are no movies in your watchlist")
            }
            .navigationTitle("Watchlist")
        }
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView(watchlist: Watchlist())
    }
}
