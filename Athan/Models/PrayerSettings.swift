//
//  PrayerSettings.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import Foundation
import CoreLocation
import Adhan

class PrayerSettings: ObservableObject {
    //    @Published var selectedCity: String = "Seattle"
    //    @Published var coordinates: Coordinates = Coordinates(latitude: 47.6062, longitude: -122.3321)
    //    @Published var timezone: String = TimeZone.current.identifier
    //    @Published var madhab: Madhab = .hanafi
    //    @Published var calculationMethod: String = "ISNA"
    
    //    @Published var selectedCity: String = "New York"
    //    @Published var coordinates: Coordinates = Coordinates(latitude: 40.7128, longitude: -74.0060)
    //    @Published var timezone: String = "America/New_York"
    //    @Published var madhab: Madhab = .hanafi
    //    @Published var calculationMethod: String = CalculationMethods.ISNA.rawValue
    
    @Published var selectedCity: String = UserDefaults.standard.string(forKey: "selectedCity") ?? ""
    @Published var coordinates = Coordinates(
        latitude: UserDefaults.standard.double(forKey: "latitude"),
        longitude: UserDefaults.standard.double(forKey: "longitude")
    )
    @Published var timezone: String = UserDefaults.standard.string(forKey: "timezone") ?? TimeZone.current.identifier
    @Published var madhab: Madhab = .hanafi
    @Published var calculationMethod: String = CalculationMethods.ISNA.rawValue
    
}
