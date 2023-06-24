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

    @AppStorage("isPromptDisabled") private var isPromptDisabled: Bool = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !isPromptDisabled {
                    notificationHandler.start()
                }
            }
            .onChange(of: isPromptDisabled) { isPromptDisabled in
                if isPromptDisabled {
                    notificationHandler.stop()
                }
            }
            .sheet(item: $notificationHandler.notificationPromptDetails) { promptDetails in
                NotificationPromptView(promptDetails: promptDetails) {
                    notificationHandler.continueAuthorizationRequest(with: true)
                } onDeclined: { dontShowAnymore in
                    isPromptDisabled = dontShowAnymore
                    notificationHandler.continueAuthorizationRequest(with: false)
                }
                .presentationDetents([.medium])
            }
            .sheet(item: $notificationHandler.enableNotificationPromptDetails) { promptDetails in
                EnableNotificationInSettingsView(promptDetails: promptDetails) { dontShowAnymore in
                    isPromptDisabled = dontShowAnymore
                    notificationHandler.continueNotAuthorizedRequest()
                }
                .presentationDetents([.medium])
            }
    }

    init(notifications: Notifications, onReceiveNotification: @escaping (UNNotification) -> Void) {
        let handler = NotificationHandler(notifications: notifications, onReceiveNotification: onReceiveNotification)
        self._notificationHandler = StateObject(wrappedValue: handler)
    }
}

@MainActor private final class NotificationHandler: NSObject, ObservableObject {

    @Published var notificationPromptDetails: NotificationPromptView.PromptDetails? = nil
    @Published var enableNotificationPromptDetails: EnableNotificationInSettingsView.PromptDetails? = nil

    private var shouldRequestAuthorization: CheckedContinuation<Bool, Never>?
    private var shouldAuthorizeNotifications: CheckedContinuation<Void, Never>?

    private let notifications: Notifications
    private let onReceiveNotification: (UNNotification) -> Void

    init(notifications: Notifications, onReceiveNotification: @escaping (UNNotification) -> Void) {
        self.notifications = notifications
        self.onReceiveNotification = onReceiveNotification
    }

    func start() {
        notifications.delegate = self
    }

    func stop() {
        notifications.delegate = nil
    }

    func continueAuthorizationRequest(with authorizationNeeded: Bool) {
        shouldRequestAuthorization?.resume(returning: authorizationNeeded)
    }

    func continueNotAuthorizedRequest() {
        shouldAuthorizeNotifications?.resume()
    }
}

extension NotificationHandler: NotificationsDelegate {

    func shouldRequestAuthorization(forMovieWith title: String) async -> Bool {
        Task { @MainActor in
            notificationPromptDetails = NotificationPromptView.PromptDetails(movieTitle: title)
        }

        let shouldRequest = await withCheckedContinuation { continuation in
            self.shouldRequestAuthorization = continuation
        }

        Task { @MainActor in
            notificationPromptDetails = nil
            shouldRequestAuthorization = nil
        }

        return shouldRequest
    }

    func shouldAuthorizeNotifications(forMovieWith title: String) async {
        Task { @MainActor in
            enableNotificationPromptDetails = EnableNotificationInSettingsView.PromptDetails(movieTitle: title)
        }

        await withCheckedContinuation { continuation in
            self.shouldAuthorizeNotifications = continuation
        }

        Task { @MainActor in
            enableNotificationPromptDetails = nil
            shouldAuthorizeNotifications = nil
        }
    }
}

extension NotificationHandler: UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        onReceiveNotification(response.notification)
        completionHandler()
    }
}

// MARK: Views

extension View {

    func onReceiveNotification(from notifications: Notifications, perform: @escaping (UNNotification) -> Void) -> some View {
        self.modifier(NotificationViewModifier(notifications: notifications, onReceiveNotification: perform))
    }
}

struct NotificationPromptView: View {

    struct PromptDetails: Identifiable {
        var id: String {
            return movieTitle
        }
        let movieTitle: String
    }

    let promptDetails: PromptDetails

    let onAccepted: () -> Void
    let onDeclined: (_ dontShowAnymore: Bool) -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                    Text("Get notified")
                }
                .font(.title.bold())

                Text("Do you want to be notified when **\(promptDetails.movieTitle)** is released?")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack {
                Button(action: { onAccepted() }) {
                    Text("Yes")
                }
                .buttonStyle(OvalButtonStyle())

                Button(action: { onDeclined(false) }) {
                    Text("No").padding(.vertical)
                }
                .foregroundStyle(.primary)

                Button(action: { onDeclined(true) }) {
                    Text("Don't show anymore").padding(.vertical)
                }
                .foregroundStyle(.primary)
            }
        }
        .padding()
    }
}

struct EnableNotificationInSettingsView: View {

    struct PromptDetails: Identifiable {
        var id: String {
            return movieTitle
        }
        let movieTitle: String
    }

    let promptDetails: PromptDetails
    let action: (_ dontShowAnymore: Bool) -> Void

    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                    Text("Get notified")
                }
                .font(.title.bold())

                Text("Go to Settings > Moviebook > Notifications and enable notifications if you want to be notified when **\(promptDetails.movieTitle)** is released.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button(action: {
                if let appSettings = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(appSettings) {
                    UIApplication.shared.open(appSettings)
                }
                action(false)
            }) {
                Text("Ok")
            }
            .buttonStyle(OvalButtonStyle())

            Button(action: { action(true) }) {
                Text("Don't show anymore").padding(.vertical)
            }
            .foregroundStyle(.primary)
        }
        .padding()
    }
}

struct NotificationPromptView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ScrollView() {}
                .sheet(item: .constant(NotificationPromptView.PromptDetails(movieTitle: "Movie title"))) { promptDetails in
                    NotificationPromptView(promptDetails: promptDetails) {} onDeclined: { _ in }
                        .presentationDetents([.medium])
                }

            ScrollView() {}
                .sheet(item: .constant(EnableNotificationInSettingsView.PromptDetails(movieTitle: "Movie title"))) { promptDetails in
                    EnableNotificationInSettingsView(promptDetails: promptDetails) { _ in }
                        .presentationDetents([.medium])
                }
        }
    }
}
