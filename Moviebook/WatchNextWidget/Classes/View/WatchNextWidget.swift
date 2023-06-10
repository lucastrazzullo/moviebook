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

    @Environment(\.widgetFamily) var widgetFamily

    var entry: Provider.Entry

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

                makeList {
                    ForEach(items, id: \.title) { item in
                        ZStack(alignment: .top) {
                            if let image = item.image {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(4)
            }
        }
    }

    private var items: [WatchNextItem] {
        switch widgetFamily {
        case .systemMedium:
            return Array(entry.items.rotateLeft(distance: entry.highlightIndex)[0..<min(4, entry.items.count)])
        case .systemLarge:
            return Array(entry.items.rotateLeft(distance: entry.highlightIndex)[0..<min(6, entry.items.count)])
        default:
            return [entry.highlightedItem].compactMap({$0})
        }
    }

    @ViewBuilder private func makeList(content: () -> some View) -> some View {
        switch widgetFamily {
        case .systemLarge, .systemExtraLarge:
            LazyVGrid(columns: [GridItem(spacing: 4), GridItem(spacing: 4), GridItem(spacing: 4)], spacing: 4) {
                content()
            }
        default:
            HStack(spacing: 4) {
                content()
            }
        }
    }
}

struct WatchNextWidget_Previews: PreviewProvider {
    static let entry: WatchNextItemEntry = WatchNextItemEntry(
        date: Date(),
        items: [
            WatchNextItem(title: "Movie title 0", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 1", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 2", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 3", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 4", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 5", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 6", image: UIImage(named: "MoviePoster")),
            WatchNextItem(title: "Movie title 7", image: UIImage(named: "MoviePoster"))
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
