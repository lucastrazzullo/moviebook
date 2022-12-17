//
//  WatchlistAddToWatchedView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 17/12/2022.
//

import SwiftUI

struct WatchlistAddToWatchedView: View {

    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var watchlist: Watchlist

    @State private var rating: Double = 6

    let item: WatchlistContent.Item

    private var toWatchReason: WatchlistToWatchReason {
        let state = watchlist.itemState(item: item)
        switch state {
        case .none:
            return .none
        case .toWatch(let reason):
            return reason
        case .watched(let reason, _):
            return reason
        }
    }

    var body: some View {
        VStack {
            Text("Add to watched")
                .font(.title)

            Form {
                switch toWatchReason {
                case .suggestion(let from, let comment):
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening").font(.title)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggested by \(from).")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(comment)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.body)
                            }
                        }

                        Spacer()
                    }
                case .none:
                    EmptyView()
                }

                Section() {
                    VStack(spacing: 32) {
                        Text("Your rating")
                            .font(.title2)
                        CircularRatingView(rating: rating, label: "Your vote", style: .prominent)
                            .frame(height: 200)
                        Slider(value: $rating, in: 0...CircularRatingView.ratingQuota, step: 0.5)
                    }
                }

                Section() {
                    Button(action: save) {
                        Text("Save")
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
            }
            .scrollContentBackground(.hidden)
        }
    }

    private func save() {
        watchlist.update(state: .watched(reason: toWatchReason, rating: rating), for: item)
        presentationMode.wrappedValue.dismiss()
    }
}

struct WatchlistAddToWatchedView_Previews: PreviewProvider {
    static var previews: some View {
        WatchlistAddToWatchedView(item: .movie(id: 954))
    }
}
