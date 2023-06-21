//
//  NotificationViewModifier.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/06/2023.
//

import SwiftUI
import MoviebookCommons

private struct NotificationViewModifier: ViewModifier {

    @Environment(\.requestManager) var requestManager
    @EnvironmentObject var watchlist: Watchlist

    @StateObject private var notificationHandler: NotificationHandler

    func body(content: Content) -> some View {
        content.onAppear {
            notificationHandler.start(watchlist: watchlist, requestManager: requestManager)
        }
    }

    init(onReceiveNotification: @escaping (UNNotification) -> Void) {
        let handler = NotificationHandler(onReceiveNotification: onReceiveNotification)
        self._notificationHandler = StateObject(wrappedValue: handler)
    }
}

private final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate, ObservableObject {

    private let notifications: Notifications
    private let onReceiveNotification: (UNNotification) -> Void

    init(onReceiveNotification: @escaping (UNNotification) -> Void) {
        self.notifications = Notifications()
        self.onReceiveNotification = onReceiveNotification
    }

    func start(watchlist: Watchlist, requestManager: RequestManager) {
        notifications.setNotificationManagerDelegate(self)
        notifications.schedule(for: watchlist, requestManager: requestManager)
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        onReceiveNotification(response.notification)
        completionHandler()
    }
}

extension View {

    func onReceiveNotification(perform: @escaping (UNNotification) -> Void) -> some View {
        self.modifier(NotificationViewModifier(onReceiveNotification: perform))
    }
}
