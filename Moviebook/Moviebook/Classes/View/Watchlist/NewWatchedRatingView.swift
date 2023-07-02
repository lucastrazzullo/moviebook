//
//  NewWatchedRatingView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 17/12/2022.
//

import SwiftUI
import MoviebookCommon

struct NewWatchedRatingView: View {

    @Environment(\.presentationMode) var presentationMode
    @Environment(\.requestManager) var requestManager

    @EnvironmentObject var watchlist: Watchlist

    @State private var title: String?
    @State private var imageUrl: URL?
    @State private var rating: Double = 6

    let itemIdentifier: WatchlistItemIdentifier

    private var toWatchInfo: WatchlistItemToWatchInfo? {
        guard let watchlistState = watchlist.itemState(id: itemIdentifier) else {
            return nil
        }

        switch watchlistState {
        case .toWatch(let info):
            return info
        case .watched(let info):
            return info.toWatchInfo
        }
    }

    var body: some View {
        ZStack {
            if let imageUrl {
                RemoteImage(
                    url: imageUrl,
                    content: { image in image.resizable().aspectRatio(contentMode: .fill) },
                    placeholder: { Color.clear }
                )
                .overlay(.regularMaterial)
            }

            VStack(spacing: 44) {
                if let title {
                    VStack {
                        Text("Add your rating")
                        Text(title).bold()
                    }
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .frame(maxWidth: 300)
                }

                if let toWatchSuggestion = toWatchInfo?.suggestion {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Suggested by")
                            Text(toWatchSuggestion.owner).bold()
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        if let comment = toWatchSuggestion.comment {
                            Text(comment)
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.body)
                        }
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(alignment: .topLeading) {
                        Image(systemName: "quote.opening")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.accentColor, in: Capsule())
                            .offset(x: -18, y: -14)
                    }
                }

                HStack(spacing: 24) {
                    Button(action: { rating = max(0, rating - 0.5) }) {
                        Image(systemName: "minus")
                            .frame(width: 18, height: 18)
                    }

                    CircularRatingView(rating: rating, label: "Your vote", style: .prominent)
                        .frame(height: 200)
                        .animation(.default, value: rating)

                    Button(action: { rating = min(CircularRatingView.ratingQuota, rating + 0.5) }) {
                        Image(systemName: "plus")
                            .frame(width: 18, height: 18)
                    }
                }
            }
            .buttonStyle(OvalButtonStyle(.normal))
            .padding(.top)
            .padding()
            .foregroundColor(nil)
            .font(.body)
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 24) {
                Button(action: save) {
                    Text("Save")
                }
                .buttonStyle(OvalButtonStyle())

                Button(action: dismiss) {
                    Text("Cancel")
                }
                .buttonStyle(.plain)
                .foregroundColor(.primary)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .onAppear {
            guard let watchlistState = watchlist.itemState(id: itemIdentifier) else {
                return
            }

            if case .watched(let info) = watchlistState, let rating = info.rating {
                self.rating = rating
            }
        }
        .task {
            switch itemIdentifier {
            case .movie(let id):
                let webService = WebService.movieWebService(requestManager: requestManager)
                let movie = try? await webService.fetchMovie(with: id)
                title = movie?.details.title
                imageUrl = movie?.details.media.posterPreviewUrl
            }
        }
    }

    private func save() {
        guard let watchlistState = watchlist.itemState(id: itemIdentifier) else {
            return
        }

        switch watchlistState {
        case .toWatch(let info):
            watchlist.update(state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: info, rating: rating, date: .now)), forItemWith: itemIdentifier)
        case .watched(var info):
            info.rating = rating
            watchlist.update(state: .watched(info: info), forItemWith: itemIdentifier)
        }

        dismiss()
    }

    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct WatchlistAddToWatchedView_Previews: PreviewProvider {
    static var previews: some View {
        NewWatchedRatingView(itemIdentifier: .movie(id: 954))
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .watched(info: WatchlistItemWatchedInfo(toWatchInfo: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "Molto bello")), rating: 6, date: .now)))
            ]))
    }
}
