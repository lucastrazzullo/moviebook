//
//  MovieCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieCardView: View {

    @State private var isOverviewExpanded: Bool = false

    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.details.title).font(.title)
                RatingView(rating: 3)
                Text("20/10/2023").font(.caption)
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text(movie.overview)
                    .font(.body)
                    .lineSpacing(8)
                    .lineLimit(isOverviewExpanded ? nil : 3)

                Button(action: { isOverviewExpanded.toggle() }) {
                    Text(isOverviewExpanded ? "Less" : "More")
                }
            }
            .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 12) {
                Text("Specs")
                    .font(.title3)
                    .padding(.bottom)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Production").bold()

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("New Line Cinema")
                        Text("Flynn Picture Company")
                        Text("Seven Bucks Productions")
                        Text("DC Films")
                    }
                }

                Divider()

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Budget").bold()
                    Spacer()
                    Text("200.000.000")
                }

                Divider()

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Incassi").bold()
                    Spacer()
                    Text("140.000.000")
                }
            }
            .font(.subheadline)
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 4).fill(.thinMaterial))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .animation(.default, value: isOverviewExpanded)
    }
}

struct MovieCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            MovieCardView(movie: MockServer.movie(with: 954))
        }
    }
}
