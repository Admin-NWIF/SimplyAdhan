//
//  PrayerTimesView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI
import Foundation
import CoreLocation

struct PrayerTimesView: View {
    @EnvironmentObject var prayerSettings: PrayerSettings
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var refreshManager: PrayerRefreshManager
    @EnvironmentObject var prayerTimesVM: PrayerTimesViewModel
    @EnvironmentObject var prayerTimesModel: PrayerTimesModel
    @Environment(\.scenePhase) var scenePhase
    
    @State private var currentPrayerName = ""
    @State private var showLocationSettings = false
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                let model = prayerTimesModel
                if model != nil {
                    Text(formattedDate(model.date))
                        .font(.headline)
                        .padding(.top)

                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundColor(.white)

                        VStack(alignment: .leading) {
                            Text("Current City")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))

                            Text(prayerSettings.selectedCity)
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(red: 0.0, green: 101/255, blue: 66/255))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    ForEach(prayerTiles(from: model), id: \ .name) { prayer in
                        HStack {
                            Image(systemName: prayer.icon)
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading) {
                                Text(prayer.name)
                                    .font(.headline)
                                Text(prayer.time)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            if prayer.name != Prayers.SUNRISE.rawValue && prayer.name != Prayers.QIYAM.rawValue {
                                // Logic for when the user toggles audio
                                Button(action: {
                                    let isOn = prayerTimesVM.toggleAudio(for: prayer.name)
                                    
                                    toastMessage = "\(prayer.name) adhan audio \(isOn ? "off" : "on")"
                                    showToast = true

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        showToast = false
                                    }
                                }) {
                                    Image(systemName: (prayerTimesVM.audioEnabled[prayer.name] ?? true) ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                        .foregroundColor(.blue)
                                }
                            } else {
                                Button(action: {
                                    // No action for SUNRISE or QIYAM
                                }) {
                                    Image(systemName: "speaker.slash.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            // Logic for when the user toggles notifications
                            Button(action: {
                                let isOn = prayerTimesVM.toggleNotifications(for: prayer.name)
                                
                                toastMessage = "\(prayer.name) notification \(isOn ? "off" : "on")"
                                showToast = true

                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    showToast = false
                                }
                                
                                if isOn == false {
                                    print("REMOVED NOTIFICATION FOR: " + prayer.name)
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(prayer.name)_\(prayerTimesVM.time(for: prayer.name))"])
                                }
                                else if isOn == true {
                                    print("ADD NOTIFICATION FOR: " + prayer.name)
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .short
                                    formatter.timeZone = TimeZone(identifier: model.options?.timezone ?? TimeZone.current.identifier)
                                    
                                    let prayerTime = prayerTimesVM.time(for: prayer.name)
                                    let body = "It's time to pray \(prayer.name) at \(formatter.string(from: prayerTime))"
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = prayer.name
                                    content.body = body
                                    content.sound = .default
                                    
                                    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: prayerTime)
                                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                                    
                                    let request = UNNotificationRequest(identifier: "\(prayer.name)_\(prayerTime)", content: content, trigger: trigger)
                                    
                                    UNUserNotificationCenter.current().add(request)
                                }
                            }) {
                                    Image(systemName: (prayerTimesVM.notificationsEnabled[prayer.name] ?? true) ? "bell.fill" : "bell.slash.fill")
                                        .foregroundColor(.blue)
                                
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                    }
                } else {
                    ProgressView("Loading prayer times…")
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onReceive(locationManager.$location.compactMap { $0 }) { coords in
            let location = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            let geocoder = CLGeocoder()
            
            if UserDefaults.standard.bool(forKey: "setLocationManually") {
                return
            }

            // Fetch both timezone and city first
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first else { return }

                // Update city
                if let city = placemark.locality {
                    DispatchQueue.main.async {
                        prayerSettings.selectedCity = city
                        UserDefaults.standard.set(city, forKey: "selectedCity")
                    }
                }
                
                // Update coordinates
                prayerSettings.coordinates = Coordinates(
                    latitude: coords.latitude,
                    longitude: coords.longitude
                )

                // Update timezone
                if let tz = placemark.timeZone {
                    DispatchQueue.main.async {
                        prayerSettings.timezone = tz.identifier
                        UserDefaults.standard.set(tz.identifier, forKey: "timezone")
                        
                        // ✅ Now that timezone is updated, fetch prayer times
                        prayerTimesVM.fetchPrayerTimes(coordinates: prayerSettings.coordinates, timezone: prayerSettings.timezone, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
//                        fetchPrayerTimesFromLocation(prayerSettings.coordinates)
                        
                        // Schedule new notifications
                        refreshManager.removeAllPendingNotifications()
                        refreshManager.scheduleMidnightRefresh(coordinates: prayerSettings.coordinates, timezone: prayerSettings.timezone, scheduleNotifications: true, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                    }
                }
            }

            // Also store raw coordinates
            UserDefaults.standard.set(coords.latitude, forKey: "latitude")
            UserDefaults.standard.set(coords.longitude, forKey: "longitude")
        }

        .onAppear {
//            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
//                print("🔔 Pending Notifications: \(requests.count)")
//                for request in requests {
//                    print("🔹 Identifier: \(request.identifier)")
//                    print("🔸 Title: \(request.content.title)")
//                    print("🔸 Body: \(request.content.body)")
//                    print("🔸 Trigger: \(String(describing: request.trigger))")
//                    print("———————")
//                }
//            }
            prayerTimesVM.audioEnabled[Prayers.SUNRISE.rawValue] = false
            prayerTimesVM.audioEnabled[Prayers.QIYAM.rawValue] = false
            prayerTimesVM.loadAudioEnabled()
            prayerTimesVM.loadNotificationsEnabled()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !UserDefaults.standard.bool(forKey: "setLocationManually") {
                locationManager.startUpdatingLocation()
            }
        }
        .overlay(
            Group {
                if showToast {
                    ToastView(message: toastMessage)
                        .padding(.bottom, 40)
                }
            },
            alignment: .bottom
        )
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    func prayerTiles(from model: PrayerTimesModel) -> [(name: String, time: String, icon: String)] {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: model.options?.timezone ?? TimeZone.current.identifier)

        return [
            (Prayers.FAJR.rawValue, formatter.string(from: model.fajr), PrayerIcons.FAJR.rawValue),
            (Prayers.SUNRISE.rawValue, formatter.string(from: model.sunrise), PrayerIcons.SUNRISE.rawValue),
            (Prayers.DHUHR.rawValue, formatter.string(from: model.dhuhr), PrayerIcons.DHUHR.rawValue),
            (Prayers.ASR.rawValue, formatter.string(from: model.asr), PrayerIcons.ASR.rawValue),
            (Prayers.MAGHRIB.rawValue, formatter.string(from: model.maghrib), PrayerIcons.MAGHRIB.rawValue),
            (Prayers.ISHA.rawValue, formatter.string(from: model.isha), PrayerIcons.ISHA.rawValue),
            (Prayers.QIYAM.rawValue, formatter.string(from: model.qiyam), PrayerIcons.QIYAM.rawValue)
        ]
    }

    func schedulePrayerNotification(title: String, body: String, at date: Date, timezone: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current

        let triggerDate = calendar.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: title, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    func getTimeZone(from coordinates: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let timeZone = placemarks?.first?.timeZone {
                completion(timeZone.description)
                print(timeZone.description)
            } else {
                print("❌ Failed to get timezone:", error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}
