//
//  ShelfView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct ShelfView: View {

    struct GeometryCalculator {

        struct Constants {
            static let detailsPadding: CGFloat = 30
        }

        let geometry: GeometryProxy
        let currentIndex: Int
        let numberOfItems: Int
        let dragOffset: CGFloat

        // MARK: Object life cycle

        init(geometry: GeometryProxy, currentIndex: Int, numberOfItems: Int, dragOffset: DragGesture.Value?) {
            self.geometry = geometry
            self.currentIndex = currentIndex
            self.numberOfItems = numberOfItems
            self.dragOffset = dragOffset?.translation.width ?? 0
        }

        // MARK: Computed properties

        var posterViewWidth: CGFloat {
            return geometry.size.width
        }

        var detailsViewWidth: CGFloat {
            return geometry.size.width - Constants.detailsPadding * 2
        }

        var postersScrollOffset: CGFloat {
            let offset = dragOffset(itemWidth: posterViewWidth)
            let listWidth = CGFloat(numberOfItems) * posterViewWidth
            return max(min(offset, 0), posterViewWidth-listWidth)
        }

        var postersContainerOffset: CGFloat {
            let offset = dragOffset(itemWidth: posterViewWidth)
            let listWidth = CGFloat(numberOfItems) * posterViewWidth

            if offset > posterViewWidth - listWidth {
                return max(offset, 0)
            } else {
                return -(posterViewWidth - listWidth - offset)
            }
        }

        var detailsScrollOffset: CGFloat {
            return -(CGFloat(currentIndex) * detailsViewWidth - dragOffset) + Constants.detailsPadding
        }

        private func dragOffset(itemWidth: CGFloat) -> CGFloat {
            return -(CGFloat(currentIndex) * posterViewWidth - dragOffset)
        }

    }

    @State private var dragOffset: DragGesture.Value?
    @State private var currentIndex: Int = 0

    let movieDetails: [MovieDetails]

    var body: some View {
        Group {
            GeometryReader { geometry in let geometryCalculator = GeometryCalculator(geometry: geometry, currentIndex: currentIndex, numberOfItems: movieDetails.count, dragOffset: dragOffset)
                Group {
                    VStack(alignment: .leading) {
                        ZStack(alignment: .bottomLeading) {
                            PostersListView(movies: movieDetails, posterElementWidth: geometryCalculator.posterViewWidth)
                                .offset(x: geometryCalculator.postersScrollOffset)

                            IndexIndicatorView(movies: movieDetails, currentIndex: currentIndex)
                                .frame(width: geometryCalculator.posterViewWidth)
                                .padding(.bottom)
                        }
                        .frame(width: geometryCalculator.posterViewWidth, alignment: .bottomLeading)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .offset(x: geometryCalculator.postersContainerOffset)

                        DetailsListView(
                            details: movieDetails,
                            detailElementWidth: geometryCalculator.detailsViewWidth,
                            detailElementPadding: GeometryCalculator.Constants.detailsPadding
                        )
                        .offset(x: geometryCalculator.detailsScrollOffset)
                        .padding(.top, 12)
                    }
                }
                .gesture(DragGesture()
                    .onChanged { gesture in
                        dragOffset = gesture
                    }
                    .onEnded { gesture in
                        if gesture.translation.width > geometryCalculator.posterViewWidth / 2 {
                            currentIndex = max(0, currentIndex - 1)
                        } else if gesture.translation.width < -geometryCalculator.posterViewWidth / 2 {
                            currentIndex = min(movieDetails.count - 1, currentIndex + 1)
                        }
                        dragOffset = nil
                    }
                )
            }
        }
        .animation(.spring(), value: dragOffset)
    }
}

// MARK: - Posters List

private struct PostersListView: View {

    let movies: [MovieDetails]
    let posterElementWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(movies, id: \.id) { movie in
                AsyncImage(url: movie.media.posterUrl, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: posterElementWidth)
                        .clipped()
                }, placeholder: {
                    Color.clear
                })
                .frame(width: posterElementWidth)
            }
        }
    }
}

// MARK: - Details List

private struct DetailsListView: View {

    let details: [MovieDetails]
    let detailElementWidth: CGFloat
    let detailElementPadding: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(details, id: \.id) { details in
                DetailsItemView(details: details)
                    .padding(.horizontal, detailElementPadding)
                    .frame(width: detailElementWidth)
            }
        }
    }
}

private struct DetailsItemView: View {

    let details: MovieDetails

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(details.title)
                RatingView(rating: 3)
                Text("20/10/2023").font(.caption)
            }

            Spacer()

            WatchlistButton(watchlistItem: .movie(id: details.id))
        }
    }
}

private struct SuggestionView: View {

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Consigliato da").font(.subheadline)
                Text("Valerio").font(.headline)
            }

            HStack {
                Text("Questo film e popt bell cos cos o frat cos.")
                    .font(.caption)
                Spacer()
            }
        }
    }
}

// MARK: - Index indicator

private struct IndexIndicatorView: View {

    let movies: [MovieDetails]
    let currentIndex: Int

    var body: some View {
        HStack {
            ForEach(movies, id: \.id) { movie in
                ZStack {
                    Circle()
                        .fill(.gray)
                        .frame(width: 6, height: 6)

                    if movie.id == movies[currentIndex].id {
                        Circle()
                            .fill(.black)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
    }
}

struct ShelfView_Previews: PreviewProvider {

    static var previews: some View {
        ShelfView(movieDetails: [
            MockServer.movie(with: 954).details,
            MockServer.movie(with: 616037).details
        ])
        .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
