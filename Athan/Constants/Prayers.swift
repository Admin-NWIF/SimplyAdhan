//
//  Prayers.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 5/28/25.
//

enum Prayers: String, CaseIterable {
    case FAJR = "Fajr"
    case SUNRISE = "Sunrise"
    case DHUHR = "Dhuhr"
    case ASR = "Asr"
    case MAGHRIB = "Maghrib"
    case ISHA = "Isha"
    case QIYAM = "Qiyam"
}

enum PrayerIcons: String {
    case FAJR = "moon.stars"
    case SUNRISE = "sunrise"
    case DHUHR = "sun.max"
    case ASR = "sun.max.fill"
    case MAGHRIB = "sunset"
    case ISHA = "moon"
    case QIYAM = "sparkles"
}
