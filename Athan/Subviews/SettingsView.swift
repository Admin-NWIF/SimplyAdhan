//
//  PrayerTimesView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI
import Adhan
import UserNotifications

extension Madhab: @retroactive Identifiable {
    public var id: Self { self }

    var label: String {
        switch self {
        case .hanafi: return "Hanafi"
        case .shafi: return "Shafi"
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var citySearchManager: CitySearchManager
    @EnvironmentObject var prayerSettings: PrayerSettings
    @EnvironmentObject var refreshManager: PrayerRefreshManager
    
    @AppStorage("setLocationManually") private var setLocationManually = false

    let methods = [
        "ISNA", "Muslim World League", "Egyptian", "Karachi",
        "Umm Al-Qura", "Dubai", "Moonsighting Committee",
        "Kuwait", "Qatar", "Singapore", "Turkey", "Tehran"
    ]

    var body: some View {
        NavigationView {
            List {
                Section {
                    Toggle("Set location manually", isOn: $setLocationManually)
                    
                    if setLocationManually {
                        NavigationLink(destination: LocationSettingsView()) {
                            Label("Location", systemImage: "location.circle")
                        }
                    }

                    NavigationLink(destination: AboutView()) {
                        Label("About", systemImage: "info.circle")
                    }
                }

                Section(header: Text("Prayer Settings")) {
                    HStack {
                        Label("Madhab", systemImage: "square.grid.2x2.fill")
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("", selection: $prayerSettings.madhab) {
                            ForEach(Madhab.allCases) { madhab in
                                Text(madhab.label).tag(madhab)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: prayerSettings.madhab) {
                            refreshManager.fetchAndSchedule(for: prayerSettings.coordinates, timezone: prayerSettings.timezone, scheduleNotifications: true, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                            refreshManager.resetMidnightRefresh(for: prayerSettings.coordinates, timezone: prayerSettings.timezone, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                        }

                    }

                    HStack {
                        Label("Method", systemImage: "slider.horizontal.3")
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("", selection: $prayerSettings.calculationMethod) {
                            ForEach(methods, id: \.self) { Text($0) }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: prayerSettings.calculationMethod) {
                            refreshManager.fetchAndSchedule(for: prayerSettings.coordinates, timezone: prayerSettings.timezone, scheduleNotifications: true, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                            refreshManager.resetMidnightRefresh(for: prayerSettings.coordinates, timezone: prayerSettings.timezone, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                        }
                    }
                    
                    HStack {
                        Label("Adhan", systemImage: "speaker.wave.2.circle.fill")
                            .foregroundColor(.primary)
                        Spacer()
//                        Picker("", selection: $prayerSettings.calculationMethod) {
//                            ForEach(methods, id: \.self) { Text($0) }
//                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section {
                    Button("🔍 Show Scheduled Notifications") {
                        printScheduledNotifications()
                    }
                    NavigationLink(destination: DebugInfoView()) {
                        Label("DebugInfo", systemImage: "location.square")
                    }
                }
               


            }
            .navigationTitle("Settings")
        }
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                citySearchManager.loadCitiesIfNeeded()
            }
        }
    }
    
    func printScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("🔔 Scheduled Notifications: \(requests.count)")
            for request in requests {
                print("🔹 Identifier: \(request.identifier)")
                print("🔸 Title: \(request.content.title)")
                print("🔸 Body: \(request.content.body)")
                
                if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                    let comps = trigger.dateComponents
                    print("🔸 Trigger Time: \(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0) \(comps.hour ?? 0):\(comps.minute ?? 0):\(comps.second ?? 0)")
                } else {
                    print("🔸 Trigger: \(String(describing: request.trigger))")
                }

                print("———————")
            }
        }
    }

}
