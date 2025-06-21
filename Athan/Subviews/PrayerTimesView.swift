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
    
//    @State private var prayerTimesModel: PrayerTimesModel?
    @State private var notificationsEnabled: [String: Bool] = [:]
    @State private var audioEnabled: [String: Bool] = [:]
    @State private var showPrayerAlert = false
    @State private var currentPrayerName = ""
    @State private var showLocationSettings = false
    
    let adhanHandler = AdhanHandler()

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

                            // Logic for whent he user toggles notifications
                            Button(action: {
                                prayerTimesVM.notificationsEnabled[prayer.name]?.toggle()
                                if prayerTimesVM.notificationsEnabled[prayer.name] == false {
                                    print(prayer.name)
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(prayer.name)_\(prayerTimesVM.time(for: prayer.name))"])
                                }
                                else if prayerTimesVM.notificationsEnabled[prayer.name] == true {
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

                            Button(action: {
                                prayerTimesVM.audioEnabled[prayer.name]?.toggle()
                            }) {
                                Image(systemName: (prayerTimesVM.audioEnabled[prayer.name] ?? true) ? "speaker.wave.2.fill" : "speaker.slash.fill")
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
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                print("🔔 Pending Notifications: \(requests.count)")
                for request in requests {
                    print("🔹 Identifier: \(request.identifier)")
                    print("🔸 Title: \(request.content.title)")
                    print("🔸 Body: \(request.content.body)")
                    print("🔸 Trigger: \(String(describing: request.trigger))")
                    print("———————")
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active && !UserDefaults.standard.bool(forKey: "setLocationManually") {
                locationManager.startUpdatingLocation()
            }
        }
        .alert(isPresented: $showPrayerAlert) {
            Alert(
                title: Text("It's time to pray \(currentPrayerName)"),
                message: Text("May Allah accept it."),
                dismissButton: .default(Text("Stop")) {
                    AudioManager.shared.stopAdhan()
                }
            )
        }
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
    
//    func fetchPrayerTimesFromLocation(_ coord: Coordinates) {
//        prayerTimesHandler.getPrayerTimes(
//            for: coord,
//            date: Date(),
//            madhab: prayerSettings.madhab,
//            method: prayerSettings.calculationMethod,
//            timezone: prayerSettings.timezone
//        ) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let model):
//                    prayerTimesModel = model
//                    for name in Prayers.allCases {
//                        notificationsEnabled[name.rawValue] = true
//                        audioEnabled[name.rawValue] = true
//                    }
//                    
//                    adhanHandler.onAdhanTriggered = { prayerName in
//                        currentPrayerName = prayerName
//                        showPrayerAlert = true
//                    }
//                    let result = adhanHandler.checkIfShouldPlayAdhan(prayerTimes: model)
//                    if let prayer = result.prayer {
//                        if result.shouldPlay == true && audioEnabled[prayer.rawValue] == true {
//                            AudioManager.shared.playAdhan(prayer: prayer.rawValue)
//                        }
//                    }
//                    
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
//    }

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
