//
//  DataModel.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import Foundation

class PrayerTimesModel: ObservableObject {
    @Published var date: Date
    @Published var fajr: Date
    @Published var sunrise: Date
    @Published var dhuhr: Date
    @Published var asr: Date
    @Published var maghrib: Date
    @Published var isha: Date
    @Published var qiyam: Date
    @Published var coordinates: Coordinates
    @Published var options: Options?

    init(date: Date, fajr: Date, sunrise: Date, dhuhr: Date, asr: Date, maghrib: Date, isha: Date, qiyam: Date, coordinates: Coordinates, options: Options?) {
        self.date = date
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
        self.qiyam = qiyam
        self.coordinates = coordinates
        self.options = options
    }
}

extension PrayerTimesModel {
    convenience init() {
        let now = Date()
        self.init(
            date: now,
            fajr: now,
            sunrise: now,
            dhuhr: now,
            asr: now,
            maghrib: now,
            isha: now,
            qiyam: now,
            coordinates: Coordinates(latitude: 0.0, longitude: 0.0),
            options: Options(timezone: TimeZone.current.identifier, method: "ISNA")
        )
    }
}

struct Coordinates {
    let latitude: Double
    let longitude: Double
}

struct Options {
    let timezone: String
    let method: String
}
