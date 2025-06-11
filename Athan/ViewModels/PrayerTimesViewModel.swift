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
    @Published var notificationsEnabled: [String: Bool] = [:]
    @Published var audioEnabled: [String: Bool] = [:]
    
    init (handler: PrayerTimesHandler, prayerTimesModel: PrayerTimesModel) {
        self.handler = handler
        self.prayerTimesModel = prayerTimesModel
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
                    Prayers.allCases.forEach {
                        self.notificationsEnabled[$0.rawValue] = true
                        self.audioEnabled[$0.rawValue] = true
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

}
