//
//  ExploreHorizontalMovieGenreSectionView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/07/2023.
//

import SwiftUI
import MoviebookCommon

struct ExploreHorizontalMovieGenreSectionView: View {

    @ObservedObject var viewModel: MovieGenresViewModel

    var body: some View {
        VStack {
            Text("Genres")
                .font(.title3)
                .bold()
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(viewModel.genres) { genre in
                        Text(genre.name)
                            .font(.caption.bold())
                            .padding(8)
                            .background(
                                viewModel.selectedGenres.contains(genre) ? .ultraThinMaterial : .ultraThickMaterial,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                            .padding(2)
                            .background(.yellow, in: RoundedRectangle(cornerRadius: 16))
                            .id(genre.id)
                            .onTapGesture {
                                if viewModel.selectedGenres.contains(genre) {
                                    self.viewModel.selectedGenres.remove(genre)
                                } else {
                                    self.viewModel.selectedGenres.insert(genre)
                                }
                            }
                    }
                }
                .padding(.horizontal, 8)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreHorizontalGenreSection_Previews: PreviewProvider {

    static var viewModel = MovieGenresViewModel()

    static var previews: some View {
        ScrollView {
            ExploreHorizontalMovieGenreSectionView(viewModel: viewModel)
        }
        .onAppear {
            viewModel.start(requestLoader: MockRequestLoader.shared)
        }
    }
}
#endif
