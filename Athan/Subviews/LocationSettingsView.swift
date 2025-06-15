//
//  PrayerTimesView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI
import CoreLocation

struct LocationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var prayerSettings: PrayerSettings
    @EnvironmentObject var refreshManager: PrayerRefreshManager
    @EnvironmentObject var citySearchManager: CitySearchManager
    @EnvironmentObject var prayerTimesVM: PrayerTimesViewModel

    @State private var searchText = ""
    @State private var searchResults: [City] = []
    @State private var searchDebounceWorkItem: DispatchWorkItem?
    @State private var hasFocused = false
    @FocusState private var isSearchFieldFocused: Bool
    
    let handler = PrayerTimesHandler()
    
    var body: some View {
        VStack(spacing: 16) {
            // 🏙️ Current city display tile
            HStack {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Current City")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(prayerSettings.selectedCity)
                        .font(.headline)
                }
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
            
            // 🔍 Search field
            TextField("Search for a city", text: $searchText)
                .font(.body) // Slightly larger
                .padding(.vertical, 12) // Inner vertical padding
                .padding(.horizontal)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .focused($isSearchFieldFocused)
                .opacity(isSearchFieldFocused ? 1 : 0.8)
                .animation(.easeInOut(duration: 0.2), value: isSearchFieldFocused)
                .onAppear {
                    guard !hasFocused else { return }
                    hasFocused = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isSearchFieldFocused = true
                    }
                }
                .onChange(of: searchText) {
                    searchDebounceWorkItem?.cancel()
                    let task = DispatchWorkItem {
                        fetchCitySuggestions(searchText)
                    }
                    searchDebounceWorkItem = task
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: task)
                }
            
            // 📍 Results list
            List($searchResults, id: \.id) { result in
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    prayerSettings.selectedCity = result.wrappedValue.name
                    let lat = result.wrappedValue.latitude
                    let lon = result.wrappedValue.longitude
                    
                    prayerSettings.coordinates = Coordinates(latitude: lat, longitude: lon)

                    getTimeZoneFromCoordinates(Coordinates(latitude: lat, longitude: lon)) { timeZone in
                        let tz = timeZone ?? TimeZone.current.identifier
                        prayerSettings.timezone = tz
                        
                        // ✅ Update PrayerTimesModel for UI
                        prayerTimesVM.fetchPrayerTimes(
                            coordinates: Coordinates(latitude: lat, longitude: lon),
                            timezone: tz,
                            madhab: prayerSettings.madhab,
                            method: prayerSettings.calculationMethod
                        )
                        
                        refreshManager.fetchAndSchedule(
                            for: Coordinates(latitude: lat, longitude: lon),
                            timezone: tz,
                            scheduleNotifications: true,
                            madhab: prayerSettings.madhab,
                            method: prayerSettings.calculationMethod
                        )
                        
                        refreshManager.resetMidnightRefresh(
                            for: Coordinates(latitude: lat, longitude: lon),
                            timezone: tz,
                            madhab: prayerSettings.madhab,
                            method: prayerSettings.calculationMethod
                        )
                    }
                    // Dismiss view
                    dismiss()
                } label: {
                    Text("\(result.wrappedValue.name), \(result.wrappedValue.adminName), \(result.wrappedValue.iso3)")
                        .lineLimit(2)
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Location")
    }
    
    func removeNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.contains("Fajr") ||
                          $0.identifier.contains("Dhuhr") ||
                          $0.identifier.contains("Asr") ||
                          $0.identifier.contains("Maghrib") ||
                          $0.identifier.contains("Isha") ||
                          $0.identifier.contains("Sunrise") }
                .map { $0.identifier }

            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }
    
    func fetchCitySuggestions(_ query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        let suggestions = citySearchManager.searchCities(prefix: searchText)
        if !suggestions.isEmpty {
            self.searchResults = suggestions
        } else {
            self.searchResults = []
        }
    }
    
    // MARK: - Helpers
    func getTimeZoneFromCoordinates(_ coordinates: Coordinates, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completion(nil)
                return
            }
            
            if let timeZone = placemarks?.first?.timeZone {
                completion(timeZone.identifier)
            } else {
                completion(nil)
            }
        }
    }
}
