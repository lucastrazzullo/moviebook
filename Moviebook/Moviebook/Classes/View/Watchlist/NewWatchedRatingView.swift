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

    let item: WatchlistContent.Item

    private var toWatchReason: Watchlist.ToWatchReason {
        let state = watchlist.itemState(item: item)
        switch state {
        case .none:
            return .none
        case .toWatch(let reason):
            return reason
        case .watched(let reason, _, _):
            return reason
        }
    }

    var body: some View {
        VStack {
            Text("Add your rating")
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
        watchlist.update(state: .watched(reason: toWatchReason, rating: .value(rating), date: .now), for: item)
        dismiss()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

#if DEBUG
struct WatchlistAddToWatchedView_Previews: PreviewProvider {
    static var previews: some View {
        NewWatchedRatingView(item: .movie(id: 954))
            .environmentObject(Watchlist(inMemoryItems: [
                .movie(id: 954): .watched(reason: .suggestion(from: "Valerio", comment: "Molto bello"), rating: .value(6), date: .now),
            ]))
    }
}
#endif
