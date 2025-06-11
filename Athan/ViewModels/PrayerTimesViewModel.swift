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
                    self.prayerTimesModel = model
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
}
