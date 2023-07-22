//
//  MoviesGenresPicker.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 09/07/2023.
//

import SwiftUI

struct MoviesGenresPicker: View {

    @ObservedObject var viewModel: MovieGenresViewModel

    var body: some View {
        Menu {
            Button(role: .destructive) {
                viewModel.selectedGenres.removeAll()
            } label: {
                Text("Remove filter")
                Image(systemName: "xmark")
            }

            ForEach(viewModel.genres, id: \.self) { genre in
                Button {
                    if viewModel.selectedGenres.contains(genre) {
                        viewModel.selectedGenres.remove(genre)
                    } else {
                        viewModel.selectedGenres.insert(genre)
                    }
                } label: {
                    Text(genre.name)
                    if viewModel.selectedGenres.contains(genre) {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack {
                Text(
                    viewModel.selectedGenres.isEmpty
                        ? "Select genres"
                        : viewModel.selectedGenres.count == 1
                            ? viewModel.selectedGenres.first!.name
                            : "Genres selected"
                )
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(.caption.bold())
            .foregroundColor(.black)
            .padding(4)
            .background(.thinMaterial.opacity(viewModel.selectedGenres.isEmpty ? 1 : 0), in: RoundedRectangle(cornerRadius: 8))
            .padding(2)
            .background(.yellow, in: RoundedRectangle(cornerRadius: 10))
            .animation(nil, value: viewModel.selectedGenres)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreGenresPicker_Previews: PreviewProvider {

    static var viewModel = MovieGenresViewModel()

    static var previews: some View {
        MoviesGenresPicker(viewModel: viewModel)
            .onAppear {
                viewModel.start(requestLoader: MockRequestLoader.shared)
            }
    }
}
#endif
