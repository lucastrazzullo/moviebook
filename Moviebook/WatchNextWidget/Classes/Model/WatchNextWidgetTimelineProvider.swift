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
        WatchNextItemEntry(date: Date(), item: WatchNextItem(title: "Watch next", image: nil))
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchNextItemEntry) -> ()) {
        let entry = WatchNextItemEntry(date: Date(), item: WatchNextItem(title: "Watch next", image: nil))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchNextItemEntry>) -> ()) {
        let items = WatchNextStorage.getItems()
        var entries: [WatchNextItemEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< items.count {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = WatchNextItemEntry(date: entryDate, item: items[hourOffset])
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WatchNextItemEntry: TimelineEntry {
    let date: Date
    let item: WatchNextItem
}
