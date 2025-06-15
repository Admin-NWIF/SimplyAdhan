//
//  AthanApp.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI
import UserNotifications
import CoreLocation

@main
struct AthanApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var prayerSettings: PrayerSettings
    @StateObject var refreshManager: PrayerRefreshManager
    @StateObject var citySearchManager: CitySearchManager
    @StateObject var locationManager: LocationManager
    @StateObject var prayerTimesVM: PrayerTimesViewModel
    @StateObject var prayerTimesModel: PrayerTimesModel
    
    @State private var didRegisterNotificationObserver = false
    @State private var hasCompletedSetup = UserDefaults.standard.string(forKey: "selectedCity") != nil
    @Environment(\.scenePhase) private var scenePhase

    
    init() {
        let prayerTimesModel = PrayerTimesModel()
        _prayerTimesModel = StateObject(wrappedValue: prayerTimesModel)
        
        let settings = PrayerSettings()
        _prayerSettings = StateObject(wrappedValue: settings)
        _refreshManager = StateObject(wrappedValue: PrayerRefreshManager(
            model: prayerTimesModel,
            coordinates: settings.coordinates,
            timezone: settings.timezone,
            madhab: settings.madhab,
            method: settings.calculationMethod
        ))
        _citySearchManager = StateObject(wrappedValue: CitySearchManager())
        _locationManager = StateObject(wrappedValue: LocationManager())
        
        let handler = PrayerTimesHandler()
        _prayerTimesVM = StateObject(wrappedValue: PrayerTimesViewModel(handler: handler, prayerTimesModel: prayerTimesModel))
    }
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedSetup {
                ContentView()
                    .environmentObject(prayerSettings)
                    .environmentObject(refreshManager)
                    .environmentObject(citySearchManager)
                    .environmentObject(locationManager)
                    .environmentObject(prayerTimesVM)
                    .environmentObject(prayerTimesModel)
                    .onAppear {
                        requestNotificationPermission()
                        if !didRegisterNotificationObserver {
                            NotificationCenter.default.addObserver(
                                forName: Notification.Name("PlayAdhanFromNotification"),
                                object: nil,
                                queue: .main
                            ) { notification in
                                let prayer = notification.userInfo?["prayer"] as? String ?? ""
                                
                                if prayer == Prayers.FAJR.rawValue {
                                    AudioManager.shared.playAdhan(prayer: Prayers.FAJR.rawValue)
                                } else {
                                    AudioManager.shared.playAdhan(prayer: Prayers.DHUHR.rawValue)
                                }
                            }
                            didRegisterNotificationObserver = true
                        }
                    }
            } else {
                SelectCityView(hasCompletedSetup: $hasCompletedSetup)
                    .environmentObject(citySearchManager)
                    .environmentObject(prayerTimesVM)
                    .environmentObject(prayerSettings)
                    .environmentObject(refreshManager)
                    .environmentObject(prayerTimesModel)
            }
        }
        .onChange(of: locationManager.hasLocationPermission) { granted in
            if granted {
                hasCompletedSetup = true
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print(error)
            } else {
            }
        }
    }
}
