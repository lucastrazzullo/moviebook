//
//  MoviePreview.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MoviePreview: View {

    let details: MovieDetails

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: imageUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .frame(width: 160, height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(details.title)
                        .lineLimit(3)
                        .font(.subheadline)
                        .frame(maxWidth: 140, alignment: .leading)

                    Text("10.10.2018")
                        .font(.caption)

                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { rating in
                            Image(systemName: "star.fill")
                                .font(.caption2)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            WatchlistButton(watchlistItem: Watchlist.WatchlistItem.movie(id: details.id))
                .font(.caption)
        }
        .contextMenu {
            WatchlistMenu(watchlistItem: Watchlist.WatchlistItem.movie(id: details.id))
        }
    }

    var imageUrl: URL? {
        guard let path = details.backdropPath else {
            return nil
        }
        return try? TheMovieDbImageRequestFactory.makeURL(format: .backdrop(path: path, size: .thumb))
    }
}

private struct WatchlistMenu: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        switch watchlist.itemState(item: watchlistItem) {
        case .toWatch:
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
        case .watched:
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Move to watchlist", systemImage: "star")
            }
            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
        case .none:
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
        }
    }
}

private struct WatchlistButton: View {

    @EnvironmentObject var watchlist: Watchlist

    let watchlistItem: Watchlist.WatchlistItem

    var body: some View {
        Menu {
            Button { watchlist.update(state: .toWatch, for: watchlistItem) } label: {
                Label("Add to watchlist", systemImage: "plus")
            }
            .disabled(watchlist.itemState(item: watchlistItem) == .toWatch)

            Button { watchlist.update(state: .watched, for: watchlistItem) } label: {
                Label("Mark as watched", systemImage: "checkmark")
            }
            .disabled(watchlist.itemState(item: watchlistItem) == .watched)

            Button { watchlist.update(state: .none, for: watchlistItem) } label: {
                Label("Remove from watchlist", systemImage: "minus")
            }
            .disabled(watchlist.itemState(item: watchlistItem) == .none)

        } label: {
            switch watchlist.itemState(item: watchlistItem) {
            case .toWatch:
                Image(systemName: "star")
            case .watched:
                Image(systemName: "checkmark")
            case .none:
                Image(systemName: "plus")
            }
        }
        .frame(width: 32, height: 32)
        .contentShape(Rectangle())
    }
}

struct MoviePreview_Previews: PreviewProvider {
    static let movie: Movie = {
        let data = try! MockServer().data(from: MovieWebService.URLFactory.makeMovieUrl(movieIdentifier: 954))
        let movie = try! JSONDecoder().decode(Movie.self, from: data)
        return movie
    }()
    static var previews: some View {
        MoviePreview(details: movie.details)
            .environmentObject(Watchlist())
    }
}
