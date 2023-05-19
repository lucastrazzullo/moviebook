//
//  EmptyWatchlistView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 18/05/2023.
//

import SwiftUI

struct EmptyWatchlistView: View {

    var onStartDiscoverySelected: () -> Void

    var body: some View {
        VStack {
            Text("Your watchlist is empty")
                .font(.headline)

            Button(action: onStartDiscoverySelected) {
                HStack {
                    Image(systemName: "rectangle.and.text.magnifyingglass")
                    Text("Start your discovery")
                }
            }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(.thinMaterial))
    }
}

struct EmptyWatchlistView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyWatchlistView(onStartDiscoverySelected: {})
            .padding()
    }
}
