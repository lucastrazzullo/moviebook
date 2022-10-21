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
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.details.title).font(.title)
                RatingView(rating: 3)
                Text("20/10/2023").font(.caption)
            }
            .padding(.horizontal, 20)

            Text(movie.overview)
                .font(.body)
                .lineSpacing(12)
                .padding(.horizontal, 20)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow)
                .frame(height: 200)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray)
                .frame(height: 100)

            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green)
                .frame(height: 50)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        MovieCardView(movie: MockServer.movie(with: 954))
    }
}
