//
//  SelectCityView.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 6/2/25.
//
import SwiftUI
import CoreLocation

struct SelectCityView: View {
    @EnvironmentObject var citySearchManager: CitySearchManager
    @EnvironmentObject var prayerSettings: PrayerSettings
    @EnvironmentObject var refreshManager: PrayerRefreshManager
    @EnvironmentObject var prayerTimesVM: PrayerTimesViewModel

    @Binding var hasCompletedSetup: Bool
    @State private var searchText = ""
    @State private var searchResults: [City] = []
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchDebounceWorkItem: DispatchWorkItem?

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Select Your City")
                    .font(.title)
                    .bold()
                    .padding(.top)

                TextField("Search city...", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .focused($isSearchFieldFocused)
                    .onChange(of: searchText) { _ in
                        debounceSearch()
                    }

                List(searchResults, id: \.id) { city in
                    Button {
                        handleCitySelection(city)
                    } label: {
                        Text("\(city.name), \(city.adminName), \(city.country)")
                    }
                }
                .listStyle(PlainListStyle())

                Spacer()
            }
            .onAppear {
                isSearchFieldFocused = true
                citySearchManager.loadCitiesIfNeeded()
            }
            .navigationBarHidden(true)
        }
    }

    func debounceSearch() {
        searchDebounceWorkItem?.cancel()
        let task = DispatchWorkItem {
            searchResults = citySearchManager.searchCities(prefix: searchText)
        }
        searchDebounceWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    func handleCitySelection(_ city: City) {
        // 🌐 Get timezone from coordinates
        let location = CLLocation(latitude: city.latitude, longitude: city.longitude)
        let geocoder = CLGeocoder()

        // Fetch both timezone and city first
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else { return }

            // Update coordinates
            prayerSettings.coordinates = Coordinates(
                latitude: city.latitude,
                longitude: city.longitude
            )
            
            // Update city
            if let city = placemark.locality {
                DispatchQueue.main.async {
                    prayerSettings.selectedCity = city
                    UserDefaults.standard.set(city, forKey: "selectedCity")
                }
            }

            // Update timezone
            if let tz = placemark.timeZone {
                DispatchQueue.main.async {
                    prayerSettings.timezone = tz.identifier
                    UserDefaults.standard.set(tz.identifier, forKey: "timezone")
                    
                    // ✅ Now that timezone is updated, fetch prayer times
                    prayerTimesVM.fetchPrayerTimes(coordinates: prayerSettings.coordinates, timezone: prayerSettings.timezone, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                    
//                    fetchPrayerTimesFromLocation(prayerSettings.coordinates)
                    
                    // Schedule new notifications
                    refreshManager.removeAllPendingNotifications()
                    refreshManager.scheduleMidnightRefresh(coordinates: prayerSettings.coordinates, timezone: prayerSettings.timezone, scheduleNotifications: true, madhab: prayerSettings.madhab, method: prayerSettings.calculationMethod)
                    
                    hasCompletedSetup = true
                }
            }
        }

        // Also store raw coordinates
        UserDefaults.standard.set(city.latitude, forKey: "latitude")
        UserDefaults.standard.set(city.longitude, forKey: "longitude")
    }
}
