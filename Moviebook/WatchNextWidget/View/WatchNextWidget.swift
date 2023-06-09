//
//  WatchNextWidget.swift
//  WatchNextWidget
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import WidgetKit
import SwiftUI

struct WatchNextWidget: Widget {
    let kind: String = "WatchNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WatchNextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct WatchNextWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        Text(entry.date, style: .time)
    }
}

struct WatchNextWidget_Previews: PreviewProvider {
    static var previews: some View {
        WatchNextWidgetEntryView(entry: WatchNextItem(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
