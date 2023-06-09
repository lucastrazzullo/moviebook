//
//  ArtistPreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import SwiftUI
import MoviebookCommons

struct ArtistPreviewView: View {

    let details: ArtistDetails
    let onSelected: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    RemoteImage(
                        url: details.imagePreviewUrl,
                        content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        },
                        placeholder: {
                            Color
                                .gray
                                .opacity(0.2)
                        }
                    )
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .padding(.trailing, 4)
                    .padding(.bottom, 4)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(details.name)
                        .lineLimit(3)
                        .font(.headline)
                        .frame(maxWidth: 140, alignment: .leading)
                }
                .padding(.vertical, 4)
            }
            .onTapGesture(perform: { onSelected?() })
        }
    }
}

#if DEBUG
struct ArtistPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            ArtistPreviewViewPreview()
                .environment(\.requestManager, MockRequestManager())
                .environmentObject(Watchlist(items: []))
        }
    }
}

private struct ArtistPreviewViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var artist: Artist?

    var body: some View {
        Group {
            if let artist {
                ArtistPreviewView(details: artist.details, onSelected: nil)
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = ArtistWebService(requestManager: requestManager)
            artist = try! await webService.fetchArtist(with: 287)
        }
    }
}
#endif
