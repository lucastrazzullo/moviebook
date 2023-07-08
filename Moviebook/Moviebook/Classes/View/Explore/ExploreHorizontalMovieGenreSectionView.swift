//
//  ExploreHorizontalMovieGenreSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/07/2023.
//

import SwiftUI
import MoviebookCommon
import MoviebookTestSupport

struct ExploreHorizontalMovieGenreSectionView: View {

    @Environment(\.requestManager) var requestManager

    @State private var genres: [MovieGenre] = []

    @Binding var selectedGenre: MovieGenre?

    var body: some View {
        Section(header: ExploreHorizontalSectionHeaderView(title: "Genres", isLoading: false)) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(genres) { genre in
                        Text(genre.name)
                            .font(.subheadline)
                            .padding(12)
                            .background(selectedGenre == genre ? .ultraThinMaterial : .ultraThickMaterial, in: RoundedRectangle(cornerRadius: 14))
                            .padding(2)
                            .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
                            .id(genre.id)
                            .onTapGesture {
                                if let selectedGenre, selectedGenre == genre {
                                    self.selectedGenre = nil
                                } else {
                                    self.selectedGenre = genre
                                }
                            }
                    }
                }
                .padding()
            }
            .listRowInsets(EdgeInsets())
        }
        .listSectionSeparator(.hidden)
        .task {
            do {
                let webService = WebService.movieWebService(requestManager: requestManager)
                self.genres = try await webService.fetchMovieGenres()
            } catch {
                print(error)
            }
        }
    }
}

private struct ExploreHorizontalSectionHeaderView: View {

    let title: String
    let isLoading: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.title3)
                .bold()
                .foregroundColor(.primary)

            if isLoading {
                ProgressView()
            }
        }
    }
}

#if DEBUG
struct ExploreHorizontalGenreSection_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ExploreHorizontalMovieGenreSectionView(selectedGenre: .constant(MovieGenre(id: 28, name: "Action")))
        }
        .listStyle(.plain)
        .environment(\.requestManager, MockRequestManager.shared)
    }
}
#endif
