//
//  ShelfView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/10/2022.
//

import SwiftUI

struct ShelfView: View {

    struct GeometryCalculator {

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
            self.currentIndex = currentIndex
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
            return geometry.size.width - detailsViewPadding * 2 + 10
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
            let offset = dragOffset(itemWidth: detailsViewWidth) + detailsViewPadding
            let listWidth = CGFloat(numberOfItems) * detailsViewWidth

            if offset > detailsViewPadding {
                return detailsViewPadding + offset / 6
            } else if offset < posterViewWidth - listWidth - detailsViewPadding {
                return offset - postersContainerOffset * 4
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

    @Environment(\.colorScheme) private var colorScheme

    @State private var horizontalDragOffset: DragGesture.Value?
    @State private var verticalDragOffset: DragGesture.Value?
    @State private var currentIndex: Int = 0
    @State private var isContentExpanded: Bool
    @State private var expandedContentHeight: CGFloat = 0

    @Binding private var navigationPath: NavigationPath

    let movieDetails: [MovieDetails]
    let cornerRadius: CGFloat

    var body: some View {
        Group {
            GeometryReader { geometry in
                let geometryCalculator = GeometryCalculator(
                    geometry: geometry,
                    currentIndex: currentIndex,
                    numberOfItems: movieDetails.count,
                    isContentExpanded: isContentExpanded,
                    horizontalDragOffset: horizontalDragOffset,
                    verticalDragOffset: verticalDragOffset
                )

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
                        .clipShape(RoundedRectangle(cornerRadius: isContentExpanded ? cornerRadius / 1.5 : cornerRadius + 2))
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .circular)
                                .stroke(makeChromeColor(), lineWidth: makeChromeWidth() )
                                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                        )
                        .offset(x: geometryCalculator.postersContainerOffset)

                        DetailsListView(
                            navigationPath: $navigationPath,
                            details: movieDetails,
                            status: verticalDragOffset != nil
                                ? .expanding(offset: -geometryCalculator.expandingScrollOffset)
                                : isContentExpanded ? .expanded : .contracted,
                            detailElementWidth: geometryCalculator.detailsViewWidth,
                            detailElementPadding: geometryCalculator.detailsViewPadding,
                            expandedHeight: $expandedContentHeight
                        )
                        .offset(x: geometryCalculator.detailsScrollOffset)
                    }
                    .offset(y: geometryCalculator.expandingScrollOffset - (isContentExpanded ? expandedContentHeight : 0))
                }
                .gesture(DragGesture()
                    .onChanged { gesture in
                        if horizontalDragOffset != nil {
                            horizontalDragOffset = gesture
                            return
                        }
                        if verticalDragOffset != nil {
                            verticalDragOffset = gesture
                            return
                        }
                        if abs(gesture.translation.width) > abs(gesture.translation.height) {
                            horizontalDragOffset = gesture
                        } else {
                            verticalDragOffset = gesture
                        }
                    }
                    .onEnded { gesture in
                        if horizontalDragOffset != nil {
                            if gesture.translation.width > geometryCalculator.posterViewWidth / 3 {
                                currentIndex = max(0, currentIndex - 1)
                            } else if gesture.translation.width < -geometryCalculator.posterViewWidth / 3 {
                                currentIndex = min(movieDetails.count - 1, currentIndex + 1)
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

    init(movieDetails: [MovieDetails], cornerRadius: CGFloat, navigationPath: Binding<NavigationPath>, expanded: Bool = false) {
        self.movieDetails = movieDetails
        self.cornerRadius = cornerRadius
        self._navigationPath = navigationPath
        self._isContentExpanded = State(initialValue: expanded)
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

    @Binding var navigationPath: NavigationPath

    let details: [MovieDetails]
    let status: DetailsItemView.Status
    let detailElementWidth: CGFloat
    let detailElementPadding: CGFloat

    @Binding var expandedHeight: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(details, id: \.id) { details in
                DetailsItemView(
                    navigationPath: $navigationPath,
                    expandedHeight: $expandedHeight,
                    details: details,
                    status: status
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

    @State private var headerHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    @Binding var navigationPath: NavigationPath
    @Binding var expandedHeight: CGFloat

    let details: MovieDetails
    let status: Status

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Group {
                HeaderView(details: details)
            }
            .padding(.top, 12)
            .background(GeometryReader { geometry in
                Color.clear.onAppear { headerHeight = geometry.size.height }
            })

            Group {
                ContentView(navigationPath: $navigationPath, details: details)
            }
            .padding(.top, 24)
            .background(GeometryReader { geometry in
                Color.clear.onAppear {
                    contentHeight = geometry.size.height
                    expandedHeight = contentHeight
                }
            })
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
            return offset / contentHeight
        }
    }
}

private struct HeaderView: View {

    let details: MovieDetails

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(details.title)
                RatingView(rating: 3)
                Text("20/10/2023").font(.caption)
            }
            .frame(width: 200, alignment: .leading)

            Spacer()

            WatchlistButton(watchlistItem: .movie(id: details.id))
                .font(.headline)
        }
    }
}

private struct ContentView: View {

    @Binding var navigationPath: NavigationPath

    let details: MovieDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Image(systemName: "square.and.pencil")
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Consigliato da").font(.caption2)
                        Text("Valerio").font(.headline)
                    }

                    HStack {
                        Text("Questo film e popt bell cos cos o frat cos e mo iamm ngopp a ddoj linee.")
                            .font(.caption)
                        Spacer()
                    }
                }
            }
            .frame(width: 240, alignment: .leading)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(12)

            VStack(alignment: .leading) {
                Text("Appartiene ad una serie").font(.subheadline)
                Text("Mission Impossible").font(.title2)

                HStack {
                    Rectangle().frame(width: 60, height: 40).cornerRadius(8)
                    Rectangle().frame(width: 60, height: 40).cornerRadius(8)
                    Rectangle().frame(width: 60, height: 40).cornerRadius(8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thickMaterial)
            .background(.orange)
            .cornerRadius(12)

            Button(action: { navigationPath.append(details.id) }) {
                Text("Open")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
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
                    if movie.id == movies[currentIndex].id {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.orange)
                            .frame(width: 3, height: 8)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.thinMaterial)
                            .frame(width: 4, height: 6)
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
        ShelfView(
            movieDetails: [
                MockServer.movie(with: 954).details,
                MockServer.movie(with: 616037).details
            ],
            cornerRadius: 16.0,
            navigationPath: .constant(NavigationPath()),
            expanded: false
        )
        .environmentObject(Watchlist(moviesToWatch: [954, 616037]))
    }
}
