//
//  MovieShelfPreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 12/07/2023.
//

import SwiftUI
import MoviebookCommon

struct MovieShelfPreviewView: View {

    @EnvironmentObject var watchlist: Watchlist

    let movieDetails: MovieDetails
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        Group {
            RemoteImage(url: movieDetails.media.posterPreviewUrl) { image in
                image.resizable()
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .aspectRatio(contentMode: .fill)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onTapGesture {
                onItemSelected(.movieWithIdentifier(movieDetails.id))
            }
        }
        .overlay(alignment: .bottom) {
            HStack(alignment: .center) {
                if movieDetails.localisedReleaseDate() > Date.now {
                    HStack(spacing: 4) {
                        Text("Release")
                        Text(movieDetails.localisedReleaseDate(), format: .dateTime.year())
                    }
                    .font(.caption2).bold()
                    .padding(6)
                    .background(.yellow, in: RoundedRectangle(cornerRadius: 6))
                    .foregroundColor(.black)
                }

                Spacer()

                IconWatchlistButton(
                    watchlistItemIdentifier: watchlistIdentifier,
                    watchlistItemReleaseDate: movieDetails.localisedReleaseDate(),
                    onItemSelected: onItemSelected
                )
            }
            .padding(10)
        }
        .id(watchlistIdentifier)
    }

    private var watchlistIdentifier: WatchlistItemIdentifier {
        return .movie(id: movieDetails.id)
    }
}

#if DEBUG
import MoviebookTestSupport

struct MovieShelfPreviewView_Previews: PreviewProvider {
    
    static var previews: some View {
        ScrollView {
            MovieShelfPreviewViewPreview()
        }
        .environment(\.requestManager, MockRequestManager.shared)
        .environmentObject(MockWatchlistProvider.shared.watchlist())
    }
}

private struct MovieShelfPreviewViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var movie: Movie?

    var body: some View {
        Group {
            if let movie {
                MovieShelfPreviewView(
                    movieDetails: movie.details,
                    onItemSelected: { _ in }
                )
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = WebService.movieWebService(requestManager: requestManager)
            movie = try! await webService.fetchMovie(with: 954)
        }
    }
}
#endif
