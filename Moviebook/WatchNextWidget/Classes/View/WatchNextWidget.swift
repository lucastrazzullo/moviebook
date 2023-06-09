//
//  WatchNextWidget.swift
//  WatchNextWidget
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import WidgetKit
import SwiftUI
import MoviebookCommons

struct WatchNextWidget: Widget {
    let kind: String = "WatchNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchNextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Watch next")
        .description("The movies in your watchlist")
    }
}

struct WatchNextWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        if let image = entry.item.image {
            Image(uiImage: image)
        } else {
            Text(entry.item.title)
        }
    }
}

struct WatchNextWidget_Previews: PreviewProvider {
    static var previews: some View {
        WatchNextWidgetEntryView(entry: WatchNextItemEntry(date: Date(), item: WatchNextItem(title: "Watch next", image: nil)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
