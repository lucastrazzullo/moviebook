//
//  NewWatchedRatingView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 17/12/2022.
//

import SwiftUI

struct NewWatchedRatingView: View {

    @Environment(\.presentationMode) var presentationMode

    @EnvironmentObject var watchlist: Watchlist

    @State private var rating: Double = 6

    let itemIdentifier: WatchlistItemIdentifier

    private var toWatchSuggestion: WatchlistItemSuggestion? {
        guard let state = watchlist.itemState(id: itemIdentifier) else {
            return nil
        }
        switch state {
        case .toWatch(let suggestion):
            return suggestion
        case .watched(let info):
            return info.suggestion
        }
    }

    var body: some View {
        VStack {
            Text("Add your rating")
                .font(.title)

            Form {
                if let toWatchSuggestion {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "quote.opening").font(.title)
                            .foregroundColor(.accentColor)

                        VStack(alignment: .leading, spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggested by \(toWatchSuggestion.owner).")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(toWatchSuggestion.comment)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .font(.body)
                            }
                        }

                        Spacer()
                    }
                } else {
                    EmptyView()
                }

                Section() {
                    VStack(spacing: 32) {
                        CircularRatingView(rating: rating, label: "Your vote", style: .prominent)
                            .frame(height: 200)
                            .animation(.default, value: rating)

                        Slider(value: $rating, in: 0...CircularRatingView.ratingQuota, step: 0.5)
                    }
                }
            }
            .scrollContentBackground(.hidden)

            VStack(spacing: 24) {
                Button(action: save) {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(action: dismiss) {
                    Text("Cancel")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top)
        .padding()
        .foregroundColor(nil)
        .font(.body)
    }

    private func save() {
        watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(suggestion: toWatchSuggestion, rating: rating, date: .now)), forItemWith: itemIdentifier)
        dismiss()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

#if DEBUG
struct WatchlistAddToWatchedView_Previews: PreviewProvider {
    static var previews: some View {
        NewWatchedRatingView(itemIdentifier: .movie(id: 954))
            .environmentObject(Watchlist(inMemoryItems: [
                WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(suggestion: WatchlistItemSuggestion(owner: "Valerio", comment: "Molto bello"), rating: 6, date: .now)))
            ]))
    }
}
#endif
