//
//  RemoteImage.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 07/06/2023.
//

import SwiftUI

struct RemoteImage<Content: View, Placeholder: View>: View {

    @Environment(\.imageLoader) private var imageLoader

    @State private var image: UIImage?

    private let url: URL?
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    init(url: URL?, content: @escaping (Image) -> Content, placeholder: @escaping () -> Placeholder) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
            }
        }
        .onAppear {
            Task {
                if let url {
                    image = try? await imageLoader.fetch(url)
                }
            }
        }
        .onChange(of: url) { url in
            Task {
                if let url {
                    image = try? await imageLoader.fetch(url)
                }
            }
        }
    }
}
