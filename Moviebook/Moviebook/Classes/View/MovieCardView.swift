//
//  MovieCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieCardView: View {

    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(movie.details.title)
                .font(.title2)

            Text(movie.overview)
                .font(.body)
                .lineSpacing(12)

            Spacer()
                .frame(height: 600)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.thickMaterial)
        .cornerRadius(12)
    }
}

struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        MovieCardView(movie: MockServer.movie(with: 954))
    }
}
