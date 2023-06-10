//
//  WatchNextWidgetTimelineProvider.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import WidgetKit
import SwiftUI
import MoviebookCommons

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> WatchNextItemEntry {
        let items = WatchNextStorage.getItems()
        return WatchNextItemEntry(date: Date(), items: [WatchNextItem(title: items.first?.title, image: items.first?.image)], highlightIndex: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchNextItemEntry) -> ()) {
        let items = WatchNextStorage.getItems()
        let entry = WatchNextItemEntry(date: Date(), items: [WatchNextItem(title: items.first?.title, image: items.first?.image)], highlightIndex: 0)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchNextItemEntry>) -> ()) {
        let items = WatchNextStorage.getItems()
        var entries: [WatchNextItemEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< items.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = WatchNextItemEntry(date: entryDate, items: items, highlightIndex: hourOffset)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WatchNextItemEntry: TimelineEntry {
    let date: Date
    let items: [WatchNextItem]
    let highlightIndex: Int

    var highlightedItem: WatchNextItem? {
        if items.indices.contains(highlightIndex) {
            return items[highlightIndex]
        } else {
            return nil
        }
    }
}
