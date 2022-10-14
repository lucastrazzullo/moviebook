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
                return max(offset, 0) / 4
            } else {
                return -(posterViewWidth - listWidth - offset) / 4
            }
        }

        var detailsScrollOffset: CGFloat {
            let offset = dragOffset(itemWidth: detailsViewWidth) + Constants.detailsPadding
            let listWidth = CGFloat(numberOfItems) * detailsViewWidth

            if offset > Constants.detailsPadding {
                return Constants.detailsPadding + offset / 6
            } else if offset < posterViewWidth - listWidth - Constants.detailsPadding {
                return offset - postersContainerOffset * 4
            } else  {
                return offset
            }
        }

        private func dragOffset(itemWidth: CGFloat) -> CGFloat {
            return -(CGFloat(currentIndex) * itemWidth - dragOffset)
        }
    }

    @State private var dragOffset: DragGesture.Value?
    @State private var currentIndex: Int = 0
    @State private var shouldShowSuggestions: Bool = false

    let movieDetails: [MovieDetails]
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            GeometryReader { geometry in let geometryCalculator = GeometryCalculator(geometry: geometry, currentIndex: currentIndex, numberOfItems: movieDetails.count, dragOffset: dragOffset)
                Group {
                    VStack(alignment: .leading) {
                        ZStack(alignment: .bottomLeading) {
                            PostersListView(movies: movieDetails, posterElementWidth: geometryCalculator.posterViewWidth)
                                .offset(x: geometryCalculator.postersScrollOffset)

                            if movieDetails.count > 1 {
                                IndexIndicatorView(movies: movieDetails, currentIndex: currentIndex)
                                    .frame(width: geometryCalculator.posterViewWidth)
                                    .padding(.bottom)
                            }
                        }
                        .frame(width: geometryCalculator.posterViewWidth, alignment: .bottomLeading)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        .offset(x: geometryCalculator.postersContainerOffset)

                        DetailsListView(
                            details: movieDetails,
                            detailElementWidth: geometryCalculator.detailsViewWidth,
                            detailElementPadding: GeometryCalculator.Constants.detailsPadding,
                            shouldShowSuggestions: shouldShowSuggestions
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

                        if gesture.translation.height > 50 {
                            shouldShowSuggestions = false
                        } else if gesture.translation.height < -50 {
                            shouldShowSuggestions = true
                        }

                        dragOffset = nil
                    }
                )
            }
        }
        .animation(.default, value: dragOffset)
        .animation(.default, value: shouldShowSuggestions)
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

    @State private var dragOffset: DragGesture.Value?

    let details: [MovieDetails]
    let detailElementWidth: CGFloat
    let detailElementPadding: CGFloat
    let shouldShowSuggestions: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(details, id: \.id) { details in
                DetailsItemView(details: details, shouldShowSuggestions: shouldShowSuggestions)
                    .padding(.horizontal, detailElementPadding)
                    .frame(width: detailElementWidth)
            }
        }
    }
}

private struct DetailsItemView: View {

    let details: MovieDetails
    let shouldShowSuggestions: Bool

    var body: some View {
        VStack(spacing: 40) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(details.title)
                    RatingView(rating: 3)
                    Text("20/10/2023").font(.caption)
                }

                Spacer()

                WatchlistButton(watchlistItem: .movie(id: details.id))
                    .font(.headline)
            }

            if shouldShowSuggestions {
                SuggestionView()
            }
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
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
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
                    if movie.id == movies[currentIndex].id {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.orange)
                            .frame(width: 8, height: 12)
                    } else {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.thinMaterial)
                            .frame(width: 6, height: 10)
                    }
                }
            }
        }
        .padding(8)
        .background(.black.opacity(0.7))
        .cornerRadius(12)
    }
}

struct ShelfView_Previews: PreviewProvider {

    static var previews: some View {
        ShelfView(movieDetails: [
            MockServer.movie(with: 954).details,
            MockServer.movie(with: 616037).details
        ], cornerRadius: 16.0)
        .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
