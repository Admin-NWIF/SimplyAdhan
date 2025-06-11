//
//  AdhanHandler.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 5/28/25.
//
import Foundation
import AVFoundation

class AdhanHandler {
    var onAdhanTriggered: ((String) -> Void)?

    func checkIfShouldPlayAdhan(prayerTimes: PrayerTimesModel) -> (shouldPlay: Bool, prayer: Prayers?) {
        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())

        let prayers: [(name: String, time: Date)] = [
            (Prayers.FAJR.rawValue, prayerTimes.fajr),
            (Prayers.DHUHR.rawValue, prayerTimes.dhuhr),
            (Prayers.ASR.rawValue, prayerTimes.asr),
            (Prayers.MAGHRIB.rawValue, prayerTimes.maghrib),
            (Prayers.ISHA.rawValue, prayerTimes.isha)
        ]

        for prayer in prayers {
            let components = calendar.dateComponents([.hour, .minute], from: prayer.time)
            if components.hour == nowComponents.hour,
               components.minute == nowComponents.minute {
                onAdhanTriggered?(prayer.name)
                return (shouldPlay: true, prayer: Prayers(rawValue: prayer.name))
            }
        }
        return (shouldPlay: false, prayer: Prayers.SUNRISE)
    }
}

