//
//  PinnedArtistsView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 03/09/2023.
//

import SwiftUI
import MoviebookCommon

struct PinnedArtistsView: View {

    @State var screenWidth: CGFloat?
    @State var contentWidth: CGFloat?
    @State var contentHeight: CGFloat?

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
            }
            .padding(.horizontal, 4)
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.size) { size in
                    contentWidth = size.width
                    contentHeight = size.height
                }
            })
            .frame(width: artistsListWidth)
        }
        .background(GeometryReader { geometry in Color.clear.onAppear {
            screenWidth = geometry.size.width
        }})
    }

    private var artistsListWidth: CGFloat? {
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
    }
}

struct PinnedArtistsViewPreview: View {

    @Environment(\.requestLoader) var requestLoader

    @State var list: [Artist] = []

    var body: some View {
        PinnedArtistsView(list: list, onItemSelected: { _ in })
            .task {
                if let artist = try? await WebService.artistWebService(requestLoader: requestLoader).fetchArtist(with: 287) {
                    list = [
                        artist,
                        artist,
                        artist,
                        artist
                    ]
                }
            }
    }
}

#endif
