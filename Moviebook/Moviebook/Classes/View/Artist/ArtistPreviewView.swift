//
//  ArtistPreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import SwiftUI

struct ArtistPreviewView: View {

    let details: ArtistDetails
    let onSelected: (() -> Void)?

    var body: some View {
        HStack(alignment: .center) {
            HStack(alignment: .center, spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncImage(url: details.imageUrl, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }, placeholder: {
                        Color
                            .gray
                            .opacity(0.2)
                    })
                    .frame(width: 160, height: 90)
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
        ArtistPreviewView(details: MockWebService.artist(with: 287).details) {}
    }
}
#endif
