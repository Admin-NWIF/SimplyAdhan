//
//  PrayerTimesViewModel.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 6/7/25.
//

import Foundation
import Combine
import Adhan
import SwiftUI

class PrayerTimesViewModel: ObservableObject {
    private let handler: PrayerTimesHandler
    
    @ObservedObject var prayerTimesModel: PrayerTimesModel
    
    @AppStorage("audioEnabled") var audioEnabledData: Data = Data()
    @Published var audioEnabled: [String: Bool] = [:] {
        didSet {
            saveAudioEnabled()
        }
    }
    
    @AppStorage("notificationsEnabled") var notificationsEnabledData: Data = Data()
    @Published var notificationsEnabled: [String: Bool] = [:] {
        didSet {
            saveNotificationsEnabled()
        }
    }

    init(handler: PrayerTimesHandler, prayerTimesModel: PrayerTimesModel) {
        self.handler = handler
        self.prayerTimesModel = prayerTimesModel
        loadAudioEnabled()
        loadNotificationsEnabled()
    }

    func fetchPrayerTimes(
        coordinates: Coordinates,
        timezone: String,
        madhab: Madhab,
        method: String
    ) {
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
                    self.prayerTimesModel.date = model.date
                    self.prayerTimesModel.fajr = model.fajr
                    self.prayerTimesModel.sunrise = model.sunrise
                    self.prayerTimesModel.dhuhr = model.dhuhr
                    self.prayerTimesModel.asr = model.asr
                    self.prayerTimesModel.maghrib = model.maghrib
                    self.prayerTimesModel.isha = model.isha
                    self.prayerTimesModel.qiyam = model.qiyam
                    self.prayerTimesModel.coordinates = model.coordinates
                    self.prayerTimesModel.options = model.options
                    
                    // Only set defaults if missing
                    Prayers.allCases.forEach {
                        let key = $0.rawValue
                        if self.notificationsEnabled[key] == nil {
                            self.notificationsEnabled[key] = true
                        }
                        if self.audioEnabled[key] == nil {
                            self.audioEnabled[key] = true
                        }
                    }

                case .failure(let error):
                    print("❌ Failed to fetch prayer times:", error)
                }
            }
        }
    }

    func time(for prayer: String) -> Date {
        switch prayer {
        case Prayers.FAJR.rawValue: return prayerTimesModel.fajr
        case Prayers.SUNRISE.rawValue: return prayerTimesModel.sunrise
        case Prayers.DHUHR.rawValue: return prayerTimesModel.dhuhr
        case Prayers.ASR.rawValue: return prayerTimesModel.asr
        case Prayers.MAGHRIB.rawValue: return prayerTimesModel.maghrib
        case Prayers.ISHA.rawValue: return prayerTimesModel.isha
        case Prayers.QIYAM.rawValue: return prayerTimesModel.qiyam
        default: return Date()
        }
    }
    
    func toggleAudio(for prayer: String) -> Bool {
        if audioEnabled[prayer] != nil {
            audioEnabled[prayer]?.toggle()
                return true
            } else {
                audioEnabled[prayer] = false
                return false
            }
        }
    
    func toggleNotifications(for prayer: String) -> Bool {
        if notificationsEnabled[prayer] != nil {
            notificationsEnabled[prayer]?.toggle()
                return true
            } else {
                notificationsEnabled[prayer] = false
                return false
        }
    }

    func loadAudioEnabled() {
        if let decoded = try? JSONDecoder().decode([String: Bool].self, from: audioEnabledData) {
            self.audioEnabled = decoded
        } else {
            print("⚠️ No audioEnabled data found in storage.")
        }
    }

    private func saveAudioEnabled() {
        if let encoded = try? JSONEncoder().encode(audioEnabled) {
            audioEnabledData = encoded
        }
    }
    
    func loadNotificationsEnabled() {
        if let decoded = try? JSONDecoder().decode([String: Bool].self, from: notificationsEnabledData) {
            self.notificationsEnabled = decoded
        } else {
            print("⚠️ No audioEnabled data found in storage.")
        }
    }

    private func saveNotificationsEnabled() {
        if let encoded = try? JSONEncoder().encode(notificationsEnabled) {
            notificationsEnabledData = encoded
        }
    }
}
