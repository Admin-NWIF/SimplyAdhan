//
//  CitySearchManager.swift
//  Athan
//
//  Created by Usman Hasan on 5/27/25.
//

import Foundation
import SwiftCSV

final class CitySearchManager: ObservableObject {
    @Published var cities: [City] = []
    private(set) var isLoaded = false
    private var trie = CityTrie()

    func loadCitiesIfNeeded() {
        if !isLoaded {
            DispatchQueue.global(qos: .userInitiated).async {
                self.trie = self.loadCitiesToTrie()
                DispatchQueue.main.async {
                }
            }
        } else {
            return
        }
    }

    func loadCitiesToTrie() -> CityTrie {
        let trie = CityTrie()

        guard let path = Bundle.main.path(forResource: "cities", ofType: "csv"),
              let csv = try? CSV<Named>(url: URL(fileURLWithPath: path)) else {
            return trie
        }

        for row in csv.rows {
            guard
                let name = row["city"],
                let asciiName = row["city_ascii"],
                let latStr = row["lat"], let lat = Double(latStr),
                let lngStr = row["lng"], let lng = Double(lngStr),
                let country = row["country"],
                let iso3 = row["iso3"],
                let adminName = row["admin_name"]
            else {
                continue
            }

            let city = City(
                name: name,
                asciiName: asciiName,
                latitude: lat,
                longitude: lng,
                country: country,
                iso3: iso3,
                adminName: adminName
            )

            trie.insert(city: city)
        }

        return trie
    }
    
    func searchCities(prefix: String) -> [City] {
        return self.trie.search(prefix: prefix)
    }
}
