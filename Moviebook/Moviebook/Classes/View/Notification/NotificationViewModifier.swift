//
//  NotificationViewModifier.swift
//  Moviebook
//
//  Created by Luca Strazzullo on 20/06/2023.
//

import SwiftUI
import MoviebookCommon

private struct NotificationViewModifier: ViewModifier {

    @Environment(\.requestManager) var requestManager

    @StateObject private var notificationHandler: NotificationHandler

    func body(content: Content) -> some View {
        content.onAppear {
            notificationHandler.start()
        }
    }

    init(notifications: Notifications, onReceiveNotification: @escaping (UNNotification) -> Void) {
        let handler = NotificationHandler(notifications: notifications, onReceiveNotification: onReceiveNotification)
        self._notificationHandler = StateObject(wrappedValue: handler)
    }
}

private final class NotificationHandler: NSObject, ObservableObject {

    private let notifications: Notifications
    private let onReceiveNotification: (UNNotification) -> Void

    init(notifications: Notifications, onReceiveNotification: @escaping (UNNotification) -> Void) {
        self.notifications = notifications
        self.onReceiveNotification = onReceiveNotification
    }

    func start() {
        notifications.delegate = self
    }
}

extension NotificationHandler: NotificationsDelegate {

    func shouldRequestAuthorization() async -> Bool {
        return true
    }

    func shouldAuthorizeNotifications() {

    }
}

extension NotificationHandler: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        onReceiveNotification(response.notification)
        completionHandler()
    }
}

extension View {

    func onReceiveNotification(from notifications: Notifications, perform: @escaping (UNNotification) -> Void) -> some View {
        self.modifier(NotificationViewModifier(notifications: notifications, onReceiveNotification: perform))
    }
}
