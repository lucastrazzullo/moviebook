//
//  SlidingCardView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI
import MoviebookCommons

struct SlidingCardView<TrailingHeaderView: View, ContentView: View>: View {

    @State private var headerHeight: CGFloat = 0
    @State private var contentOffset: CGFloat = 0
    @State private var contentInset: CGFloat = 0
    @State private var isImageLoaded: Bool = false

    private let cardOverlap: CGFloat = 24

    // MARK: Internal properties

    @Binding var navigationPath: NavigationPath

    let title: String
    let posterUrl: URL?

    @ViewBuilder let trailingHeaderView: () -> TrailingHeaderView
    @ViewBuilder let content: () -> ContentView

    var body: some View {
        ZStack(alignment: .top) {
            GeometryReader { geometry in
                PosterView(
                    isImageLoaded: $isImageLoaded,
                    imageHeight: $contentInset,
                    contentOffset: contentOffset,
                    posterUrl: posterUrl
                )

                if !isImageLoaded {
                    LoaderView().onAppear {
                        contentInset = geometry.size.height
                    }
                }

                ObservableScrollView(scrollOffset: $contentOffset, showsIndicators: false) { _ in
                    VStack {
                        Spacer()
                            .frame(height: isImageLoaded
                                   ? max(0, contentInset - geometry.safeAreaInsets.top - cardOverlap)
                                   : max(0, geometry.size.height - geometry.safeAreaInsets.top)
                            )

                        CardView(content: content)
                    }
                }
            }
        }
        .animation(.default, value: isImageLoaded)
        .safeAreaInset(edge: .top) {
            HeaderView(
                navigationPath: $navigationPath,
                headerHeight: $headerHeight,
                title: title,
                shouldShowHeader: isImageLoaded && contentOffset - contentInset + headerHeight > 0,
                trailingView: trailingHeaderView
            )
        }
    }
}

private struct HeaderView<TrailingView: View>: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var navigationPath: NavigationPath
    @Binding var headerHeight: CGFloat

    let title: String
    let shouldShowHeader: Bool

    @ViewBuilder let trailingView: () -> TrailingView

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .center) {
                WatermarkView {
                    if !navigationPath.isEmpty {
                        Button(action: { navigationPath.removeLast() }) {
                            Image(systemName: "chevron.left")
                        }
                    } else {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "chevron.down")
                        }
                    }
                }

                if shouldShowHeader {
                    Text(title)
                        .lineLimit(2)
                        .font(.headline)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .frame(maxWidth: .infinity)
                } else {
                    Spacer()
                }

                trailingView()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 20)
        .background(
            GeometryReader { geometry in
                Rectangle()
                    .fill(.background.opacity(0.2))
                    .background(.regularMaterial)
                    .opacity(shouldShowHeader ? 1 : 0)
                    .onAppear {
                        headerHeight = geometry.size.height
                    }
            }
        )
        .transition(.opacity)
        .animation(.easeOut(duration: 0.2), value: shouldShowHeader)
    }
}

private struct CardView<Content: View>: View {

    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            content()
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(.background)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.12), radius: 4, y: -8)
    }
}

#if DEBUG
struct SlidingCardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SlidingCardViewPreview()
                .environmentObject(Watchlist(items: [
                    WatchlistItem(id: .movie(id: 954), state: .toWatch(info: .init(date: .now, suggestion: .init(owner: "Valerio", comment: "This is really nice"))))
                ]))
                .environment(\.requestManager, MockRequestManager())
        }
    }
}

private struct SlidingCardViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var movie: Movie?

    var body: some View {
        Group {
            if let movie {
                SlidingCardView(
                    navigationPath: .constant(.init()),
                    title: movie.details.title,
                    posterUrl: movie.details.media.posterUrl,
                    trailingHeaderView: {
                        WatermarkView {
                            Image(systemName: "play")
                        }
                    },
                    content: {
                        MovieContentView(
                            navigationPath: .constant(.init()),
                            movie: movie,
                            onVideoSelected: { _ in }
                        )
                    }
                )
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = MovieWebService(requestManager: requestManager)
            movie = try! await webService.fetchMovie(with: 954)
        }
    }
}
#endif
