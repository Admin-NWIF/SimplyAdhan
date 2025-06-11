//
//  AppDelegate.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 5/28/25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when user taps a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let prayerTitle = response.notification.request.content.title
        NotificationCenter.default.post(
            name: Notification.Name("PlayAdhanFromNotification"),
            object: nil,
            userInfo: ["prayer": prayerTitle]
        )
        completionHandler()
    }
}
