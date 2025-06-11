//
//  PrayerRefreshManager.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import Foundation
import UserNotifications
import Adhan
import SwiftUICore

class PrayerRefreshManager: ObservableObject {
    private var timer: Timer?
    let handler = PrayerTimesHandler()
    @ObservedObject var model: PrayerTimesModel

    init(model: PrayerTimesModel, coordinates: Coordinates, timezone: String, scheduleNotifications: Bool = true, madhab: Madhab, method: String) {
        self.model = model
        fetchAndSchedule(for: coordinates, timezone: timezone, scheduleNotifications: true, madhab: madhab, method: method)
        scheduleMidnightRefresh(coordinates: coordinates, timezone: timezone, scheduleNotifications: scheduleNotifications, madhab: madhab, method: method)
    }

    func scheduleMidnightRefresh(coordinates: Coordinates, timezone: String, scheduleNotifications: Bool, madhab: Madhab, method: String) {
        let now = Date()
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current

        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime)!

        let interval = nextMidnight.timeIntervalSince(now)
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.timeZone = calendar.timeZone
        
        self.fetchAndSchedule(for: coordinates, timezone: timezone, scheduleNotifications: scheduleNotifications, madhab: madhab, method: method)

        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            self.scheduleMidnightRefresh(coordinates: coordinates, timezone: timezone, scheduleNotifications: scheduleNotifications, madhab: madhab, method: method)
        }
    }
    
    func removeAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func fetchAndSchedule(for coordinates: Coordinates, timezone: String, scheduleNotifications: Bool, madhab: Madhab, method: String) {
        handler.getPrayerTimes(
            for: coordinates,
            date: Date(),
            madhab: madhab,
            method: method,
            timezone: timezone
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let model):
                    // ✅ Copy values into shared model
                    self.model.date = model.date
                    self.model.fajr = model.fajr
                    self.model.sunrise = model.sunrise
                    self.model.dhuhr = model.dhuhr
                    self.model.asr = model.asr
                    self.model.maghrib = model.maghrib
                    self.model.isha = model.isha
                    self.model.qiyam = model.qiyam
                    self.model.coordinates = model.coordinates
                    self.model.options = model.options
                    if scheduleNotifications {
                        self.scheduleAllNotifications(for: model)
                    }
                case .failure(let error):
                    print("❌ Midnight fetch error:", error)
                }
            }
        }
    }
    
    func resetMidnightRefresh(for coordinates: Coordinates, timezone: String, madhab: Madhab, method: String) {
        timer?.invalidate() // 🔁 Cancel current timer
        scheduleMidnightRefresh(coordinates: coordinates, timezone: timezone, scheduleNotifications: true, madhab: madhab, method: method)
    }

    private func scheduleAllNotifications(for model: PrayerTimesModel) {
        removeAllPendingNotifications()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: model.options?.timezone ?? TimeZone.current.identifier)

        let prayers = [
            (Prayers.FAJR.rawValue, model.fajr),
            (Prayers.SUNRISE.rawValue, model.sunrise),
            (Prayers.DHUHR.rawValue, model.dhuhr),
            (Prayers.ASR.rawValue, model.asr),
            (Prayers.MAGHRIB.rawValue, model.maghrib),
            (Prayers.ISHA.rawValue, model.isha),
            (Prayers.QIYAM.rawValue, model.qiyam)
        ]

        for (title, time) in prayers {
            let body = "It's time to pray \(title) at \(formatter.string(from: time))"
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default

            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: time)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

            let request = UNNotificationRequest(identifier: "\(title)_\(time)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
            print("scheduled notifs")
        }
    }
}
