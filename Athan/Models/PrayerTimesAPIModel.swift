//
//  PrayerTimesAPIModel.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import Foundation

// Decoding AlAdhan API response
struct PrayerTimesAPIResponse: Codable {
    let data: PrayerData
}

struct PrayerData: Codable {
    let timings: [String: String]
}

// Decoding Nominatim geolocation results
struct NominatimResult: Codable, Identifiable {
    var id: Int { place_id } // For use in ForEach or List

    let place_id: Int
    let display_name: String
    let lat: String
    let lon: String
}


// Mapping readable method names to IDs
struct PrayerMethod {
    static func id(for method: String) -> Int {
        switch method.lowercased() {
        case "isna": return 2
        case "mwl": return 3
        case "umm al-qura": return 4
        case "egyptian": return 5
        default: return 2
        }
    }
}
