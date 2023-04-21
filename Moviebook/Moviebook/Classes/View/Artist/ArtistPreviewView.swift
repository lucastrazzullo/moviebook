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
        Text(details.name)
    }
}

struct ArtistPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        ArtistPreviewView(details: ArtistDetails(
            id: 10,
            name: "Brad Pitt",
            popularity: 32.234,
            imagePath: "/1k9MVNS9M3Y4KejBHusNdbGJwRw.jpg")
        )
    }
}
