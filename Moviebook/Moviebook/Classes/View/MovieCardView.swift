//
//  MovieCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/09/2022.
//

import SwiftUI

struct MovieCardView: View {

    @EnvironmentObject var watchlist: Watchlist

    @State private var isOverviewExpanded: Bool = false

    let movie: Movie

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.details.title).font(.title)
                RatingView(rating: 3)
                Text("20/10/2023").font(.caption)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Non hai ancora visto questo film")
                    .font(.headline)
                Text("Se aggiungi il film alla watchlist potrai associare alcune informazioni personali che troverai successivamente raccolte in questo box.")
                    .font(.subheadline)

                Button(action: { }) {
                    Text("Aggiungi")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).stroke(.orange))

            VStack(alignment: .leading, spacing: 12) {
                Text("Overview")
                    .font(.title3)
                    .padding(.bottom)

                Text(movie.overview)
                    .font(.body)
                    .lineSpacing(8)
                    .lineLimit(isOverviewExpanded ? nil : 3)

                Button(action: { isOverviewExpanded.toggle() }) {
                    Text(isOverviewExpanded ? "Less" : "More")
                }
            }
            .padding(.horizontal)

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
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(.thinMaterial))
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
                .environmentObject(Watchlist(moviesToWatch: [954]))
        }
    }
}
