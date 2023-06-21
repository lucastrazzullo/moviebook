//
//  Spotlight.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 08/05/2023.
//

import Foundation
import CoreSpotlight
import MoviebookCommon

enum Spotlight {

    static func deeplink(from userActivity: NSUserActivity) -> Deeplink? {
        if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
            let url = URL(string: uniqueIdentifier),
            let deeplink = Deeplink(rawValue: url) {
            return deeplink
        } else {
            return nil
        }
    }

    // MARK: Indexing

    static func index(movie: Movie) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.displayName = movie.details.title
        attributeSet.thumbnailURL = movie.details.media.posterPreviewUrl

        let url = Deeplink.movie(identifier: movie.id).rawValue
        let searchableItem = CSSearchableItem(uniqueIdentifier: url.absoluteString, domainIdentifier: "movie", attributeSet: attributeSet)

        CSSearchableIndex.default().indexSearchableItems([searchableItem])
    }

    static func index(artist: Artist) {
        let attributeSet = CSSearchableItemAttributeSet(contentType: .content)
        attributeSet.displayName = artist.details.name
        attributeSet.thumbnailURL = artist.details.imagePreviewUrl

        let url = Deeplink.artist(identifier: artist.id).rawValue
        let searchableItem = CSSearchableItem(uniqueIdentifier: url.absoluteString, domainIdentifier: "movie", attributeSet: attributeSet)

        CSSearchableIndex.default().indexSearchableItems([searchableItem])
    }
}
