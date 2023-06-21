//
//  MovieVideoPlayer.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 04/11/2022.
//

import SwiftUI
import YouTubePlayerKit
import MoviebookCommon

struct MovieVideoPlayer: View {

    let video: MovieVideo
    let autoplay: Bool

    var body: some View {
        Group {
            switch video.source {
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

    init(video: MovieVideo, autoplay: Bool = false) {
        self.video = video
        self.autoplay = autoplay
    }
}

struct TrailerPlayer_Previews: PreviewProvider {
    static var previews: some View {
        MovieVideoPlayer(video: MovieVideo(id: "id", name: "Trailer", type: .trailer, source: .youtube(id: "x5DhuDSArTI")))
    }
}
