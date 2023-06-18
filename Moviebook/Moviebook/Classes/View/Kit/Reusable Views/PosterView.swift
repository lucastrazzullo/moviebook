//
//  PosterView.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 22/04/2023.
//

import SwiftUI

struct PosterView: View {

    @Binding var isImageLoaded: Bool
    @Binding var imageHeight: CGFloat

    let contentOffset: CGFloat
    let posterUrl: URL?

    var body: some View {
        GeometryReader { mainGeometry in
            RemoteImage(
                url: posterUrl,
                content: { image in
                    image
                        .resizable()
                        .background(GeometryReader { imageGeometry in Color.clear.onAppear {
                            let imageRatio = imageGeometry.size.width / imageGeometry.size.height
                            imageHeight = mainGeometry.size.width / imageRatio
                            isImageLoaded = true
                        }})
                        .aspectRatio(contentMode: .fill)
                },
                placeholder: { Color.black }
            )
            .frame(
                width: UIScreen.main.bounds.width,
                height: max(0, isImageLoaded ? imageHeight - contentOffset : mainGeometry.size.height)
            )
            .clipped()
            .ignoresSafeArea(.all, edges: .top)
        }
    }
}

#if DEBUG
struct PosterView_Previews: PreviewProvider {
    static var previews: some View {
        PosterView(isImageLoaded: .constant(false),
                   imageHeight: .constant(300),
                   contentOffset: 0,
                   posterUrl: nil)
    }
}
#endif
