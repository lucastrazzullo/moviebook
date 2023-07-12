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
    @State private var currentRating: Double = 6
    @State private var ratingOffset: Double = 0

    private var rating: Double {
        return currentRating + ratingOffset
    }

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

    private let quota: Double = 10.0

    let itemIdentifier: WatchlistItemIdentifier

    var body: some View {
        ZStack {
            if let imageUrl {
                RemoteImage(
                    url: imageUrl,
                    content: { image in image.resizable().aspectRatio(contentMode: .fill) },
                    placeholder: { Color.clear }
                )
                .overlay(.thickMaterial)
            }

            VStack(spacing: 32) {
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
                                .frame(maxWidth: 220)
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
                } else if let imageUrl {
                    RemoteImage(
                        url: imageUrl,
                        content: { image in image.resizable().aspectRatio(contentMode: .fit) },
                        placeholder: { Color.clear }
                    )
                    .cornerRadius(24)
                }

                VStack(spacing: 24) {
                    VStack {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(rating, format: .number).font(.title)
                            Text("/").font(.body)
                            Text(quota, format: .number).font(.body)
                        }
                        Text("Your vote").foregroundColor(.secondary)
                    }

                    Group {
                        GeometryReader { geometry in
                            Rectangle()
                                .foregroundStyle(.thinMaterial)
                                .overlay(
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .foregroundColor(.yellow)
                                            .frame(width: geometry.size.width * (rating / quota))

                                        HStack(spacing: geometry.size.width / quota) {
                                            ForEach(0..<9) { _ in
                                                Rectangle()
                                                    .foregroundStyle(.primary.opacity(0.3))
                                                    .frame(width: 1)
                                            }
                                        }
                                        .frame(width: geometry.size.width)
                                    }
                                )
                                .compositingGroup()
                                .cornerRadius(24)
                                .shadow(color: .black.opacity(0.2), radius: 8)
                                .simultaneousGesture(DragGesture(minimumDistance: 2)
                                    .onChanged { value in
                                        let offset = value.translation.width / geometry.size.width * quota
                                        let minimumAllowedOffset = -currentRating
                                        let maximumAllowedOffset = quota - currentRating
                                        let measuredOffset = max(minimumAllowedOffset, min(maximumAllowedOffset, offset))
                                        let roundedOffset = round(measuredOffset)
                                        if ratingOffset != roundedOffset {
                                            ratingOffset = roundedOffset
                                        }
                                    }
                                    .onEnded { value in
                                        currentRating = currentRating + ratingOffset
                                        ratingOffset = 0
                                    }
                                )
                        }
                    }
                    .frame(height: 64)
                    .onChange(of: ratingOffset) { _ in
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }
                .padding(24)
                .background(.thickMaterial)
                .background(.primary)
                .compositingGroup()
                .cornerRadius(28)
            }
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
                self.currentRating = rating
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

#if DEBUG
import MoviebookTestSupport
struct WatchlistAddToWatchedView_Previews: PreviewProvider {
    static var previews: some View {
        NewWatchedRatingView(itemIdentifier: .movie(id: 954))
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: false, withRating: true)))

        NewWatchedRatingView(itemIdentifier: .movie(id: 954))
            .environmentObject(MockWatchlistProvider.shared.watchlist(configuration: .watchedItems(withSuggestion: true, withRating: true)))
    }
}
#endif
