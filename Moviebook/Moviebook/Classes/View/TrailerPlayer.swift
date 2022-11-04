//
//  TrailerPlayer.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import SwiftUI
import YouTubePlayerKit

struct TrailerPlayer: View {

    let trailer: MovieTrailer
    let autoplay: Bool

    var body: some View {
        Group {
            switch trailer {
            case .youtube(let id):
                YouTubePlayerView(YouTubePlayer(
                    source: .video(id: id),
                    configuration: YouTubePlayer.Configuration(
                        allowsPictureInPictureMediaPlayback: true,
                        autoPlay: autoplay,
                        playInline: false
                    )
                ))
            }
        }
        .background(.black)
    }

    init(trailer: MovieTrailer, autoplay: Bool = false) {
        self.trailer = trailer
        self.autoplay = autoplay
    }
}

struct TrailerPlayer_Previews: PreviewProvider {
    static var previews: some View {
        TrailerPlayer(trailer: .youtube(id: "x5DhuDSArTI"))
    }
}
