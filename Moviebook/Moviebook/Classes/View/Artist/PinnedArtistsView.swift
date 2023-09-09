//
//  PinnedArtistsView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 03/09/2023.
//

import SwiftUI
import MoviebookCommon

struct PinnedArtistsView: View {

    let list: [Artist]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {

        VStack(alignment: .center, spacing: 8) {
            Text("Favourite artists".uppercased())
                .font(.heroSubheadline)

            Capsule()
                .foregroundColor(.secondaryAccentColor)
                .frame(width: 28, height: 4)

            Group {
                if !list.isEmpty {
                    FullListView(
                        list: list,
                        onItemSelected: onItemSelected
                    )
                } else {
                    EmptyListView(
                        onItemSelected: onItemSelected
                    )
                }
            }
            .frame(minHeight: 24)
        }
    }
}

private struct EmptyItem: View {

    let showsPlusIcon: Bool
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .foregroundStyle(.thinMaterial)

            if showsPlusIcon {
                Image(systemName: "plus")
            }
        }
        .onTapGesture {
            onItemSelected(.popularArtists)
        }
    }
}

private struct EmptyListView: View {

    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        Text("Here you can pin your favourite artists")
            .font(.caption)

        HStack {
            ForEach(0...4, id: \.self) { index in
                EmptyItem(showsPlusIcon: index == 2, onItemSelected: onItemSelected)
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct FullListView: View {

    @State var screenWidth: CGFloat?
    @State var contentWidth: CGFloat?
    @State var contentHeight: CGFloat?
    @State var itemAspectRatio: CGFloat?

    let list: [Artist]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(list) { artist in
                    RemoteImage(url: artist.details.imagePreviewUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .background(GeometryReader { geometry in
                                Color.clear.onAppear {
                                    itemAspectRatio = geometry.size.width / geometry.size.height
                                }
                            })
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                            .frame(width: 80)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .bottom) {
                        if artist.highlightedRelease != nil {
                            Text("New")
                                .font(.caption2.bold())
                                .padding(4)
                                .background(Color.secondaryAccentColor, in: RoundedRectangle(cornerRadius: 4))
                                .foregroundColor(.black)
                                .padding(.bottom, 4)
                                .fixedSize(horizontal: true, vertical: false)
                                .opacity(contentHeight ?? 0 > 90 ? 1 : 0)
                                .animation(.easeOut(duration: 0.125), value: contentHeight)
                        }
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .onTapGesture {
                        onItemSelected(.artistWithIdentifier(artist.id))
                    }
                }

                EmptyItem(showsPlusIcon: true, onItemSelected: onItemSelected)
                    .aspectRatio(itemAspectRatio ?? 0.5, contentMode: .fit)
            }
            .padding(.horizontal, 4)
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.size) { size in
                    contentWidth = size.width
                    contentHeight = size.height
                }
            })
            .frame(width: listWidth)
        }
        .background(GeometryReader { geometry in Color.clear.onAppear {
            screenWidth = geometry.size.width
        }})
    }

    private var listWidth: CGFloat? {
        guard let screenWidth, let contentWidth else {
            return nil
        }

        return screenWidth > contentWidth ? screenWidth : nil
    }
}

#if DEBUG

import MoviebookTestSupport

struct PinnedArtistsView_Previews: PreviewProvider {
    static var previews: some View {
        PinnedArtistsViewPreview()
            .frame(height: 180)
            .environment(\.requestLoader, MockRequestLoader.shared)
            .environmentObject(MockFavouritesProvider.shared.favourites())

        PinnedArtistsViewPreview()
            .frame(height: 180)
            .environment(\.requestLoader, MockRequestLoader.shared)
            .environmentObject(MockFavouritesProvider.shared.favourites(empty: true))
    }
}

struct PinnedArtistsViewPreview: View {

    @Environment(\.requestLoader) var requestLoader
    @EnvironmentObject var favourites: Favourites

    @State var list: [Artist] = []

    var body: some View {
        PinnedArtistsView(list: list, onItemSelected: { _ in })
            .task {
                do {
                    list = try await withThrowingTaskGroup(of: Artist.self) { group in
                        var result = [Artist]()

                        favourites.items.forEach { item in
                            switch item.id {
                            case .artist(let id):
                                group.addTask {
                                    return try await WebService
                                        .artistWebService(requestLoader: requestLoader)
                                        .fetchArtist(with: id)
                                }
                            }
                        }

                        for try await item in group {
                            result.append(item)
                        }

                        return result
                    }
                } catch {}
            }
    }
}

#endif
