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

    let list: [ArtistDetails]
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(list) { details in
                    RemoteImage(url: details.imagePreviewUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .fixedSize(horizontal: true, vertical: false)
                    .onTapGesture {
                        onItemSelected(.artistWithIdentifier(details.id))
                    }
                }
            }
            .padding(.horizontal, 4)
            .background(GeometryReader { geometry in
                Color.clear.onChange(of: geometry.size.width) { width in
                    contentWidth = width
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

    @State var list: [ArtistDetails] = []

    var body: some View {
        PinnedArtistsView(list: list, onItemSelected: { _ in })
            .task {
                if let artist = try? await WebService.artistWebService(requestLoader: requestLoader).fetchArtist(with: 287) {
                    list = [
                        artist.details,
                        artist.details,
                        artist.details,
                        artist.details
                    ]
                }
            }
    }
}

#endif
