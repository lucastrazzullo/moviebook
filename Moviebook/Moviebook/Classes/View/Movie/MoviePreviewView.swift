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
    let details: MovieDetails
    let onItemSelected: (NavigationItem) -> Void

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
                        Text(details.title)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.headline)

                        Group {
                            if details.localisedReleaseDate() > .now {
                                Text("Coming on \(details.localisedReleaseDate().formatted(.dateTime.year()))")
                                    .bold()
                                    .padding(4)
                                    .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundColor(.black)
                            } else {
                                Text(details.localisedReleaseDate(), format: .dateTime.year())
                            }
                        }
                        .font(.caption)
                    }

                    RatingView(rating: details.rating)
                }
                .padding(.vertical, 4)
            }
            .onTapGesture(perform: { onItemSelected(.movieWithIdentifier(details.id)) })

            Spacer()

            IconWatchlistButton(
                watchlistItemIdentifier: .movie(id: details.id),
                watchlistItemReleaseDate: details.localisedReleaseDate(),
                onItemSelected: onItemSelected
            )
        }
    }

    init(details: MovieDetails, style: Style = .poster, onItemSelected: @escaping (NavigationItem) -> Void) {
        self.details = details
        self.style = style
        self.onItemSelected = onItemSelected
    }

    private var imageUrl: URL? {
        switch style {
        case .backdrop:
            return details.media.backdropPreviewUrl
        case .poster:
            return details.media.posterPreviewUrl
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
            .environmentObject(MockWatchlistProvider.shared.watchlist())
            .environment(\.requestLoader, MockRequestLoader.shared)
        }
    }
}

private struct MoviePreviewViewPreview: View {

    @Environment(\.requestLoader) var requestLoader
    @State var movie: Movie?

    let movieId: Movie.ID
    let style: MoviePreviewView.Style

    var body: some View {
        Group {
            if let movie {
                MoviePreviewView(details: movie.details, style: style, onItemSelected: { _ in }).padding()
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = WebService.movieWebService(requestLoader: requestLoader)
            movie = try! await webService.fetchMovie(with: movieId)
        }
    }
}
#endif
