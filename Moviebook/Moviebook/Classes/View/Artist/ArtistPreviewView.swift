//
//  ArtistPreviewView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/04/2023.
//

import SwiftUI

struct ArtistPreviewView: View {

    let details: ArtistDetails

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

                    if let birthday = details.birthday {
                        Text(birthday, format: .dateTime.year()).font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

#if DEBUG
struct ArtistPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistPreviewView(details: ArtistDetails(
            id: 10,
            name: "Brad Pitt",
            birthday: ArtistDetails.birthdayDateFormatter.date(from: "1963-12-18"),
            imageUrl: URL(string: "https://image.tmdb.org/t/p/h632/1k9MVNS9M3Y4KejBHusNdbGJwRw.jpg")!
        ))
    }
}
#endif
