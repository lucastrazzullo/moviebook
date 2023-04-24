//
//  ArtistContentView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI

struct ArtistContentView: View {

    @State private var isOverviewExpanded: Bool = false

    @Binding var navigationPath: NavigationPath

    let artist: Artist

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            HeaderView(details: artist.details)
            
            if let biography = artist.details.biography, !biography.isEmpty {
                ExpandibleOverviewView(isExpanded: $isOverviewExpanded, overview: biography)
            }

            SpecsView(title: "Specs", items: specs)

            if !artist.filmography.isEmpty {
                FilmographyView(
                    movies: artist.filmography,
                    onMovieSelected: { identifier in
                        navigationPath.append(identifier)
                    }
                )
            }
        }
        .padding(4)
        .animation(.default, value: isOverviewExpanded)
    }

    private var specs: [SpecsView.Item] {
        var items: [SpecsView.Item] = []

        if let birthday = artist.details.birthday {
            items.append(.date(birthday, label: "Birthday"))
        }

        if let deathday = artist.details.deathday {
            items.append(.date(deathday, label: "Death"))
        }

        return items
    }
}

private struct HeaderView: View {

    let details: ArtistDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(details.name).font(.title)

            HStack {
                if let birthday = details.birthday {
                    Text(birthday, format: .dateTime.year()).font(.caption)
                }

                if let deathday = details.deathday {
                    Text("-")
                    Text(deathday, format: .dateTime.year()).font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

private struct FilmographyView: View {

    let movies: [MovieDetails]
    let onMovieSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Text("Filmography").font(.title2)
                .padding(.horizontal)

            LazyVStack {
                ForEach(movies) { movieDetails in
                    Group {
                        MoviePreviewView(details: movieDetails) {
                            onMovieSelected(movieDetails.id)
                        }
                    }
                    .padding(8)
                    .background {
                        if let index = movies.firstIndex(of: movieDetails), index % 2 == 0 {
                            RoundedRectangle(cornerRadius: 8)
                                .foregroundStyle(.ultraThinMaterial.opacity(0.4))
                        }
                    }
                }
            }
        }
        .foregroundColor(.white)
        .padding(4)
        .padding(.vertical)
        .background(RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.8)))
    }
}

#if DEBUG
struct ArtistCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            ArtistContentView(navigationPath: .constant(.init()),
                              artist: MockWebService.artist(with: 287))
            .environment(\.requestManager, MockRequestManager())
            .environmentObject(Watchlist(items: [:]))
        }
    }
}
#endif
