//
//  WatchNextWidgetTimelineProvider.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 09/06/2023.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> WatchNextItem {
        WatchNextItem(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (WatchNextItem) -> ()) {
        let entry = WatchNextItem(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchNextItem>) -> ()) {
        var entries: [WatchNextItem] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = WatchNextItem(date: entryDate)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct WatchNextItem: TimelineEntry {
    let date: Date
}
