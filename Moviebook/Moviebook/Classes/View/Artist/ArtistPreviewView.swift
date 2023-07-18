//
//  ArtistPreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import SwiftUI
import MoviebookCommon

struct ArtistPreviewView: View {

    let details: ArtistDetails
    let shouldShowCharacter: Bool
    let onItemSelected: (NavigationItem) -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: details.imagePreviewUrl, content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }, placeholder: {
                Color
                    .gray
                    .opacity(0.2)
            })
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading) {
                Text(details.name)
                    .font(.caption.bold())

                if let character = details.character, shouldShowCharacter {
                    Text(character)
                        .font(.caption2)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .foregroundStyle(.ultraThinMaterial)
            )
            .padding(4)
        }
        .onTapGesture(perform: { onItemSelected(.artistWithIdentifier(details.id)) })
    }
}

#if DEBUG
import MoviebookTestSupport

struct ArtistPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(showsIndicators: false) {
            ArtistPreviewViewPreview()
                .environment(\.requestManager, MockRequestManager.shared)
                .environmentObject(MockWatchlistProvider.shared.watchlist())
        }
    }
}

private struct ArtistPreviewViewPreview: View {

    @Environment(\.requestManager) var requestManager
    @State var artist: Artist?

    var body: some View {
        Group {
            if let artist {
                ArtistPreviewView(details: artist.details, shouldShowCharacter: true, onItemSelected: { _ in })
            } else {
                LoaderView()
            }
        }
        .task {
            let webService = WebService.artistWebService(requestManager: requestManager)
            artist = try! await webService.fetchArtist(with: 287)
        }
    }
}
#endif
