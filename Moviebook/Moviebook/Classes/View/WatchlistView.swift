//
//  WatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 02/09/2022.
//

import SwiftUI
import CoreData

struct WatchlistView: View {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    var onStartDiscoverySelected: () -> Void = {}

    var body: some View {
        NavigationView {
            Group {
                if watchlist.isEmpty {
                    VStack {
                        Text("Your watchlist is empty")
                            .font(.headline)

                        Button(action: onStartDiscoverySelected) {
                            Label("Start your discovery", systemImage: "rectangle.and.text.magnifyingglass")
                        }.buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section(header: Text("To Watch")) {
                            Text("Movie")
                        }

                        Section(header: Text("Watched")) {
                            Text("Movie")
                        }
                    }
                }
            }
            .navigationTitle("Watchlist")
        }
    }
}

struct WatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistView()
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist())
    }
}
