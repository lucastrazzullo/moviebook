//
//  ShelfView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct ShelfView: View {

    @Environment(\.colorScheme) private var colorScheme

    @State private var horizontalDragOffset: DragGesture.Value?
    @State private var verticalDragOffset: DragGesture.Value?
    @State private var currentIndex: Int = 0
    @State private var isContentExpanded: Bool

    private let expandedContentHeight: CGFloat = 360

    let movies: [Movie]
    let cornerRadius: CGFloat
    let openMovie: (Movie) -> Void
    let openMovieWithIdentifier: (Movie.ID) -> Void

    var body: some View {
        Group {
            GeometryReader { geometry in
                let geometryCalculator = GeometryCalculator(
                    geometry: geometry,
                    currentIndex: currentIndex,
                    numberOfItems: movies.count,
                    isContentExpanded: isContentExpanded,
                    horizontalDragOffset: horizontalDragOffset,
                    verticalDragOffset: verticalDragOffset
                )

                Group {
                    VStack(alignment: .leading) {
                        ZStack(alignment: .bottomLeading) {
                            PostersListView(
                                posterUrls: movies.map(\.details.media.posterUrl),
                                posterElementWidth: geometryCalculator.posterViewWidth
                            )
                            .offset(x: geometryCalculator.postersScrollOffset)
                            .onTapGesture {
                                if movies.indices.contains(currentIndex) {
                                    openMovie(movies[currentIndex])
                                }
                            }

                            if movies.count > 1 {
                                IndexIndicatorView(
                                    movieIdentifiers: movies.map(\.id),
                                    currentIndex: currentIndex
                                )
                                .frame(width: geometryCalculator.posterViewWidth)
                                .padding(.bottom)
                            }
                        }
                        .frame(width: geometryCalculator.posterViewWidth, alignment: .bottomLeading)
                        .clipShape(RoundedRectangle(cornerRadius: isContentExpanded ? cornerRadius / 1.5 : cornerRadius + 2))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                                .stroke(makeChromeColor(), lineWidth: makeChromeWidth() )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        )
                        .offset(x: geometryCalculator.postersContainerOffset)

                        DetailsListView(
                            movies: movies,
                            status: verticalDragOffset != nil
                                ? .expanding(offset: -geometryCalculator.expandingScrollOffset)
                                : isContentExpanded ? .expanded : .contracted,
                            detailElementWidth: geometryCalculator.detailsViewWidth,
                            detailElementPadding: geometryCalculator.detailsViewPadding,
                            onMovieSelected: openMovie,
                            onMovieIdentifierSelected: openMovieWithIdentifier
                        )
                        .offset(x: geometryCalculator.detailsContainerHorizontalOffset)
                    }
                    .offset(y: geometryCalculator.expandingScrollOffset - (isContentExpanded ? expandedContentHeight : 0))
                }
                .gesture(DragGesture()
                    .onChanged { gesture in

                        if !isContentExpanded {
                            if horizontalDragOffset != nil {
                                horizontalDragOffset = gesture
                                return
                            }
                        }

                        if verticalDragOffset != nil {
                            verticalDragOffset = gesture
                            return
                        }

                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            if !isContentExpanded {
                                horizontalDragOffset = gesture
                            }
                        } else {
                            verticalDragOffset = gesture
                        }
                    }
                    .onEnded { gesture in
                        if horizontalDragOffset != nil {
                            if gesture.translation.width > geometryCalculator.posterViewWidth / 3 {
                                currentIndex = max(0, currentIndex - 1)
                            } else if gesture.translation.width < -geometryCalculator.posterViewWidth / 3 {
                                currentIndex = min(movies.count - 1, currentIndex + 1)
                            }
                        }

                        if verticalDragOffset != nil {
                            if gesture.translation.height > 80 {
                                isContentExpanded = false
                            } else if gesture.translation.height < -80 {
                                isContentExpanded = true
                            }
                        }

                        horizontalDragOffset = nil
                        verticalDragOffset = nil
                    }
                )
            }
        }
        .animation(.default, value: horizontalDragOffset)
        .animation(.spring(), value: verticalDragOffset)
    }

    private func makeChromeColor() -> Color {
        switch colorScheme {
        case .dark:
            return Color.black
        default:
            return Color.white
        }
    }

    private func makeChromeWidth() -> CGFloat {
        return isContentExpanded ? 0 : 8
    }

    // MARK: Object life cycle

    init(movies: [Movie],
         cornerRadius: CGFloat,
         expanded: Bool = false,
         onOpenMovie: @escaping (Movie) -> Void,
         onOpenMovieWithIdentifier: @escaping (Movie.ID) -> Void) {
        self.movies = movies
        self.cornerRadius = cornerRadius
        self.openMovie = onOpenMovie
        self.openMovieWithIdentifier = onOpenMovieWithIdentifier

        self._isContentExpanded = State(initialValue: expanded)
    }
}

// MARK: - Helper types

private struct GeometryCalculator {

    private let geometry: GeometryProxy
    private let currentIndex: Int
    private let numberOfItems: Int
    private let isContentExpanded: Bool
    private let horizontalOffset: CGFloat
    private let verticalOffset: CGFloat

    // MARK: Object life cycle

    init(geometry: GeometryProxy,
         currentIndex: Int,
         numberOfItems: Int,
         isContentExpanded: Bool,
         horizontalDragOffset: DragGesture.Value?,
         verticalDragOffset: DragGesture.Value?) {
        self.geometry = geometry
        self.currentIndex = max(min(currentIndex, numberOfItems - 1), 0)
        self.numberOfItems = numberOfItems
        self.isContentExpanded = isContentExpanded
        self.horizontalOffset = horizontalDragOffset?.translation.width ?? 0
        self.verticalOffset = verticalDragOffset?.translation.height ?? 0
    }

    // MARK: Computed properties

    var posterViewWidth: CGFloat {
        return geometry.size.width
    }

    var detailsViewPadding: CGFloat {
        return isContentExpanded ? 10 : 30
    }

    var detailsViewWidth: CGFloat {
        return geometry.size.width - detailsViewPadding * 2
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

    var detailsContainerHorizontalOffset: CGFloat {
        let offset = dragOffset(itemWidth: detailsViewWidth + detailsViewPadding) + detailsViewPadding
        let listWidth = CGFloat(numberOfItems) * detailsViewWidth

        if offset > detailsViewPadding {
            return detailsViewPadding + horizontalOffset / 6
        } else if offset < posterViewWidth - listWidth - detailsViewPadding {
            return offset - horizontalOffset + horizontalOffset / 6
        } else  {
            return offset
        }
    }

    var expandingScrollOffset: CGFloat {
        return verticalOffset
    }

    private func dragOffset(itemWidth: CGFloat) -> CGFloat {
        return -(CGFloat(currentIndex) * itemWidth - horizontalOffset)
    }
}

// MARK: - Posters List

private struct PostersListView: View {

    let posterUrls: [URL?]
    let posterElementWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            ForEach(posterUrls, id: \.self) { posterUrl in
                AsyncImage(url: posterUrl, content: { image in
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

    let movies: [Movie]
    let status: DetailsItemView.Status
    let detailElementWidth: CGFloat
    let detailElementPadding: CGFloat
    let onMovieSelected: (Movie) -> Void
    let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: detailElementPadding) {
            ForEach(movies, id: \.id) { movie in
                DetailsItemView(
                    movie: movie,
                    status: status,
                    onMovieSelected: onMovieSelected,
                    onMovieIdentifierSelected: onMovieIdentifierSelected
                )
                .padding(.horizontal, detailElementPadding)
                .frame(width: detailElementWidth)
            }
        }
    }
}

private struct DetailsItemView: View {

    enum Status: Equatable {
        case expanding(offset: CGFloat)
        case expanded
        case contracted
    }

    let movie: Movie
    let status: Status

    let onMovieSelected: (Movie) -> Void
    let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Group {
                HeaderView(movieDetails: movie.details)
            }
            .padding(.top, 12)

            Group {
                Image(systemName: "chevron.compact.up")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .opacity(1 - makeOpacity())

            Group {
                ContentView(
                    movie: movie,
                    onMovieSelected: onMovieSelected,
                    onMovieIdentifierSelected: onMovieIdentifierSelected
                )
            }
            .padding(.top, 24)
            .opacity(makeOpacity())
        }
    }

    private func makeOpacity() -> CGFloat {
        switch status {
        case .contracted:
            return 0
        case .expanded:
            return 1
        case .expanding(let offset):
            return offset / 100
        }
    }
}

private struct HeaderView: View {

    let movieDetails: MovieDetails

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(movieDetails.title)
                RatingView(rating: movieDetails.rating)
                if let releaseDate = movieDetails.release {
                    Text(releaseDate, format: .dateTime.year()).font(.caption)
                }
            }
            .frame(width: 200, alignment: .leading)

            Spacer()

            WatermarkWatchlistButton(watchlistItem: .movie(id: movieDetails.id))
        }
    }
}

private struct ContentView: View {

    @MainActor final class Content: ObservableObject {

        @Published private(set) var movie: Movie

        init(movie: Movie) {
            self.movie = movie
        }

        func load(requestManager: RequestManager) async {
            if let collection = movie.collection, collection.list == nil {
                do {
                    self.movie.collection?.list = try await MovieWebService(requestManager: requestManager).fetchCollection(with: collection.id).list
                } catch {
                    print(error)
                }
            }
        }
    }

    @Environment(\.requestManager) var requestManager

    @StateObject private var content: Content

    private let onMovieSelected: (Movie) -> Void
    private let onMovieIdentifierSelected: (Movie.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let collection = content.movie.collection, let list = collection.list, !list.isEmpty {
                VStack(alignment: .leading) {
                    Text("Belong to:")
                    Text(collection.name).font(.title2)
                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(list) { movieDetails in
                                Group {
                                    AsyncImage(url: movieDetails.media.posterPreviewUrl, content: { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    }, placeholder: {
                                        Color
                                            .gray
                                            .opacity(0.2)
                                    })
                                    .frame(height: 120)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .padding(.trailing, 4)
                                .padding(.bottom, 4)
                                .onTapGesture {
                                    onMovieIdentifierSelected(movieDetails.id)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                .padding()
                .background(.thickMaterial)
                .cornerRadius(12)
            }

            Button(action: { onMovieSelected(content.movie) }) {
                Text("Open")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        }
        .task {
            await content.load(requestManager: requestManager)
        }
    }

    init(movie: Movie,
         onMovieSelected: @escaping (Movie) -> Void,
         onMovieIdentifierSelected: @escaping (Movie.ID) -> Void) {
        self._content = StateObject(wrappedValue: Content(movie: movie))
        self.onMovieSelected = onMovieSelected
        self.onMovieIdentifierSelected = onMovieIdentifierSelected
    }
}

// MARK: - Index indicator

private struct IndexIndicatorView: View {

    let movieIdentifiers: [Movie.ID]
    let currentIndex: Int

    var body: some View {
        WatermarkView {
            ForEach(movieIdentifiers, id: \.self) { movieIdentifier in
                ZStack {
                    if movieIdentifiers.indices.contains(currentIndex), movieIdentifier == movieIdentifiers[currentIndex] {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.orange)
                            .frame(width: 8, height: 12)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.thinMaterial)
                            .frame(width: 6, height: 8)
                    }
                }
            }
        }
    }
}

#if DEBUG
struct ShelfView_Previews: PreviewProvider {

    static var previews: some View {
        ShelfView(
            movies: [
                MockServer.movie(with: 954),
                MockServer.movie(with: 616037)
            ],
            cornerRadius: 16.0,
            expanded: true,
            onOpenMovie: { _ in },
            onOpenMovieWithIdentifier: { _ in }
        )
        .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
#endif
