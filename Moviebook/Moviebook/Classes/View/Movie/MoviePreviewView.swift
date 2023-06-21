//
//  MoviePreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI
import MoviebookCommon

struct MoviePreviewView: View {

    enum Style {
        case poster
        case backdrop
    }

    @EnvironmentObject var watchlist: Watchlist

    let style: Style
    let details: MovieDetails?
    let onSelected: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    RemoteImage(url: imageUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .aspectRatio(contentMode: .fill)
                    .frame(width: imageFrame.width, height: imageFrame.height)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(details?.title ?? "Loading")
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)

                        if let releaseDate = details?.release {
                            Group {
                                if releaseDate > .now {
                                    HStack(spacing: 4) {
                                        Text("Coming on")
                                        Text(releaseDate, format: .dateTime.year()).bold()
                                    }
                                    .padding(4)
                                    .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundColor(.black)
                                } else {
                                    Text(releaseDate, format: .dateTime.year())
                                }
                            }
                            .font(.caption)
                        }
                    }

                    if let rating = details?.rating {
                        RatingView(rating: rating)
                    }
                }
                .padding(.vertical, 4)
            }
            .onTapGesture(perform: { onSelected?() })

            if let movieId = details?.id {
                Spacer()
                IconWatchlistButton(watchlistItemIdentifier: .movie(id: movieId))
                    .font(.headline)
            }
        }
    }

    init(details: MovieDetails?, style: Style = .poster, onSelected: (() -> Void)? = nil) {
        self.details = details
        self.style = style
        self.onSelected = onSelected
    }

    private var imageUrl: URL? {
        switch style {
        case .backdrop:
            return details?.media.backdropPreviewUrl
        case .poster:
            return details?.media.posterPreviewUrl
        }
    }

    private var imageFrame: CGSize {
        switch style {
        case .backdrop:
            return CGSize(width: 120, height: 100)
        case .poster:
            return CGSize(width: 120, height: 180)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct MoviePreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack {
                MoviePreviewViewPreview(movieId: 954, style: .poster)
                MoviePreviewViewPreview(movieId: 353081, style: .poster)
                MoviePreviewViewPreview(movieId: 616037, style: .backdrop)
            }
            .environmentObject(Watchlist(items: [
                WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: nil))),
                WatchlistItem(id: .movie(id: 616037), state: .toWatch(info: .init(date: .now, suggestion: nil)))
            ]))
            .environment(\.requestManager, MockRequestManager())
        }
    }
}

private struct MoviePreviewViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var movie: Movie?

    let movieId: Movie.ID
    let style: MoviePreviewView.Style

    var body: some View {
        Group {
            if let movie {
                MoviePreviewView(details: movie.details, style: style).padding()
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = MovieWebService(requestManager: requestManager)
            movie = try! await webService.fetchMovie(with: movieId)
        }
    }
}
#endif
