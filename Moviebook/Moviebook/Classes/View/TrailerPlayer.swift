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

    var body: some View {
        Group {
            switch trailer {
            case .youtube(let id):
                YouTubePlayerView(YouTubePlayer(source: .video(id: id)))
            }
        }
        .background(.black)
    }
}

struct TrailerPlayer_Previews: PreviewProvider {
    static var previews: some View {
        TrailerPlayer(trailer: .youtube(id: "x5DhuDSArTI"))
    }
}
