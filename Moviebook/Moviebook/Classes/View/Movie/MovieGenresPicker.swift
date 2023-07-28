//
//  MovieGenresPicker.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 09/07/2023.
//

import SwiftUI
import MoviebookCommon

struct MovieGenresPicker: View {

    @Binding var selectedGenre: MovieGenre?

    let genres: [MovieGenre]

    var body: some View {
        Menu {
            if selectedGenre != nil {
                Button(role: .destructive) {
                    self.selectedGenre = nil
                } label: {
                    Text("Remove filter")
                    Image(systemName: "xmark")
                }
            }

            ForEach(genres, id: \.self) { genre in
                Button {
                    if selectedGenre == genre {
                        selectedGenre = nil
                    } else {
                        selectedGenre = genre
                    }
                } label: {
                    Text(genre.name)
                    if selectedGenre == genre {
                        Image(systemName: "checkmark")
                    }
                }
            }
        } label: {
            HStack {
                Text(selectedGenre?.name ?? "Select genre")
                Image(systemName: "chevron.up.chevron.down")
            }
            .font(.caption.bold())
            .foregroundColor(.black)
            .padding(4)
            .background(.thinMaterial.opacity(selectedGenre == nil ? 1 : 0), in: RoundedRectangle(cornerRadius: 8))
            .padding(2)
            .background(.yellow, in: RoundedRectangle(cornerRadius: 10))
            .animation(nil, value: selectedGenre)
        }
    }
}

#if DEBUG
import MoviebookTestSupport

struct ExploreGenresPicker_Previews: PreviewProvider {

    static var previews: some View {
        MovieGenresPicker(
            selectedGenre: .constant(nil),
            genres: [
                MovieGenre(id: 0, name: "Action"),
                MovieGenre(id: 1, name: "Adventure")
            ]
        )
    }
}
#endif
