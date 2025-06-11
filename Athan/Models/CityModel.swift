//
//  CityModel.swift
//  Athan
//
//  Created by Usman Hasan on 5/27/25.
//

import Foundation

struct City: Identifiable {
    let id = UUID()
    let name: String
    let asciiName: String
    let latitude: Double
    let longitude: Double
    let country: String
    let iso3: String
    let adminName: String
}
