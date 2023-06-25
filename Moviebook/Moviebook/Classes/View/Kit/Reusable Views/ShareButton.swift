//
//  ShareButton.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 25/06/2023.
//

import SwiftUI
import MoviebookCommon

struct ShareButton: View {

    @Environment(\.imageLoader) private var imageLoader

    @State private var image: Image?
    @State private var imageError: Error?

    let deeplink: Deeplink
    let previewTitle: String
    let previewImageUrl: URL

    var body: some View {
        Group {
            if let image {
                ShareLink(item: deeplink.rawValue,
                          message: Text("Check this out on Moviebook"),
                          preview: SharePreview(previewTitle, image: image)) {
                    Image(systemName: "square.and.arrow.up")
                }
            } else if imageError != nil {
                ShareLink(item: deeplink.rawValue,
                          message: Text("Check this out on Moviebook: **\(previewTitle)**")) {
                    Image(systemName: "square.and.arrow.up")
                }
            } else {
                ProgressView()
                    .controlSize(.small)
                    .tint(.white)
            }
        }
        .task {
            do {
                self.image = Image(uiImage: try await imageLoader.fetch(previewImageUrl))
            } catch {
                self.imageError = error
            }
        }
    }
}

struct ShareButton_Previews: PreviewProvider {
    static var previews: some View {
        WatermarkView {
            ShareButton(deeplink: .movie(identifier: 954),
                        previewTitle: "Mission Impossible",
                        previewImageUrl: URL(string: "https://image.tmdb.org/t/p/w780/geEjCGfdmRAA1skBPwojcdvnZ8A.jpg")!)
        }
    }
}
