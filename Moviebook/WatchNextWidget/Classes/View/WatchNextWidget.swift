//
//  WatchNextWidget.swift
//  WatchNextWidget
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import WidgetKit
import SwiftUI
import MoviebookCommon

struct WatchNextWidget: Widget {
    let kind: String = "WatchNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchNextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Watch next")
        .description("Your watchlist")
    }
}

struct WatchNextWidgetEntryView : View {

    let entry: Provider.Entry

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let backgroungImage = entry.highlightedItem?.image {
                    Image(uiImage: backgroungImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)

                    Rectangle()
                        .background(.thinMaterial)

                }

                WatchNextWidgetContentView(entry: entry) { item in
                    if let image = item?.image {
                        Link(destination: item?.deeplink?.rawValue ?? Deeplink.watchlist.rawValue) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(4)
            }
        }
    }
}

private struct WatchNextWidgetContentView<ItemContent: View>: View {

    @Environment(\.widgetFamily) var widgetFamily

    let entry: Provider.Entry
    @ViewBuilder let itemContent: (WatchNextItem?) -> ItemContent

    var body: some View {
        switch widgetFamily {
        case .systemLarge:
            let items = Array(entry.items.rotateLeft(distance: entry.highlightIndex)[0..<min(6, entry.items.count)])
            LazyVGrid(columns: [GridItem(spacing: 4), GridItem(spacing: 4), GridItem(spacing: 4)], spacing: 4) {
                ForEach(items, id: \.title) { item in
                    itemContent(item)
                }
            }
        case .systemMedium:
            let items = Array(entry.items.rotateLeft(distance: entry.highlightIndex)[0..<min(4, entry.items.count)])
            HStack(spacing: 4) {
                ForEach(items, id: \.title) { item in
                    itemContent(item)
                }
            }
        default:
            itemContent(entry.highlightedItem)
                .widgetURL(entry.highlightedItem?.deeplink?.rawValue)
        }
    }
}

struct WatchNextWidget_Previews: PreviewProvider {
    static let entry: WatchNextItemEntry = WatchNextItemEntry(
        date: Date(),
        items: [
            WatchNextItem(title: "Movie title 0", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 1", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 2", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 3", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 4", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 5", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 6", image: UIImage(named: "MoviePoster"), deeplink: nil),
            WatchNextItem(title: "Movie title 7", image: UIImage(named: "MoviePoster"), deeplink: nil)
        ],
        highlightIndex: 0
    )

    static var previews: some View {
        WatchNextWidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        WatchNextWidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
        WatchNextWidgetEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}
