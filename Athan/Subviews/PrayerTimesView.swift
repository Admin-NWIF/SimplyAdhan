//
//  PrayerTimesView.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import SwiftUI
import Foundation
import CoreLocation

struct Citynames: Identifiable {
    let id = UUID()
    let name: String
    let country: String

    var displayName: String {
        "\(name), \(country)"
    }
}

struct PrayerTimesView: View {
    @EnvironmentObject var prayerSettings: PrayerSettings
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var refreshManager: PrayerRefreshManager
    @EnvironmentObject var prayerTimesVM: PrayerTimesViewModel
    @EnvironmentObject var prayerTimesModel: PrayerTimesModel
    //    @State private var prayerTimesModel: PrayerTimesModel?
    @State private var notificationsEnabled: [String: Bool] = [:]
    @State private var audioEnabled: [String: Bool] = [:]
    @State private var showPrayerAlert = false
    @State private var currentPrayerName = ""
    @State private var showLocationSettings = false
    @State private var scrollProxy: ScrollViewProxy?
    
    let adhanHandler = AdhanHandler()
    @State private var showCitySearch = false
    @State private var searchText = ""
    @State private var allCities: [Citynames] = []
    
    let preferredCities: [Citynames] = [
        Citynames(name: "Makkah", country: "Saudi Arabia"),
        Citynames(name: "Medina", country: "Saudi Arabia"),
        Citynames(name: "New York City", country: "USA"),
        Citynames(name: "Dallas", country: "USA"),
        Citynames(name: "Los Angeles", country: "USA"),
        Citynames(name: "Houston", country: "USA"),
        Citynames(name: "Seattle", country: "USA")
    ]
    
    func loadCitiesFromCSV() -> [Citynames] {
        guard let url = Bundle.main.url(forResource: "cities", withExtension: "csv"),
              let content = try? String(contentsOf: url) else {
            return []
        }

        var seen = Set<String>()
        var cities: [Citynames] = []
        let lines = content.components(separatedBy: .newlines)

        for line in lines.dropFirst() where !line.isEmpty {
            let components = parseCSVLine(line)

            if components.count >= 5 {
                let cityName = components[1].trimmingCharacters(in: .whitespaces)
                var country = components[4].trimmingCharacters(in: .whitespaces)

                // Fix Korea formatting
                if country.contains("Korea") && country.contains(",") {
                    let parts = country.components(separatedBy: ",")
                    if parts.count == 2 {
                        let fixed = parts[1].trimmingCharacters(in: .whitespaces) + " " + parts[0].trimmingCharacters(in: .whitespaces)
                        country = fixed
                    }
                }

                let key = "\(cityName.lowercased()),\(country.lowercased())"
                if !seen.contains(key) {
                    seen.insert(key)
                    cities.append(Citynames(name: cityName, country: country))
                }
            }
        }

        return cities
    }

    // CSV line parser that handles quoted fields
    func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var value = ""
        var insideQuotes = false

        for char in line {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(value)
                value = ""
            } else {
                value.append(char)
            }
        }

        result.append(value)
        return result
    }


    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                let model = prayerTimesModel
                if model != nil {
                    Text(formattedDate(model.date))
                        .font(.headline)
                        .padding(.top)

                    Button(action: {
                        withAnimation {
                            showCitySearch.toggle()
                            searchText = ""
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            scrollProxy?.scrollTo("top", anchor: .top)
                        }
                    }) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.white)

                            VStack(alignment: .leading) {
                                Text("Current City")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                Text(prayerSettings.selectedCity)
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(red: 0.0, green: 101/255, blue: 66/255))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    
                    if showCitySearch {
                        VStack(spacing: 0) {
                            TextField("", text: $searchText, prompt: Text("Search city...").foregroundColor(.white.opacity(0.8)))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(red: 0.0, green: 101/255, blue:66/255))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            
                            ScrollViewReader { proxy in
                                List {
                                    EmptyView().id("top")
                                    
                                    ForEach(preferredCities
                                        .filter {
                                            searchText.isEmpty ||
                                            $0.name.lowercased().hasPrefix(searchText.lowercased()) ||
                                            $0.displayName.lowercased().hasPrefix(searchText.lowercased())
                                        }
                                        .sorted { $0.name.lowercased() < $1.name.lowercased() }
                                    ) { city in
                                        Button {
                                            // Update city name
                                            prayerSettings.selectedCity = city.name
                                            UserDefaults.standard.set(true, forKey: "hasManuallySelectedCity")
                                            showCitySearch = false
                                            searchText = ""
                                            
                                            // Geocode city to get coordinates + timezone
                                            let geocoder = CLGeocoder()
                                            geocoder.geocodeAddressString(city.displayName) { placemarks, error in
                                                guard let placemark = placemarks?.first,
                                                      let coord = placemark.location?.coordinate,
                                                      let timeZone = placemark.timeZone else {
                                                    print("❌ Failed to geocode \(city.displayName)")
                                                    return
                                                }
                                                
                                                DispatchQueue.main.async {
                                                    // Update prayerSettings
                                                    prayerSettings.coordinates = Coordinates(latitude: coord.latitude, longitude: coord.longitude)
                                                    prayerSettings.timezone = timeZone.identifier
                                                    UserDefaults.standard.set(coord.latitude, forKey: "latitude")
                                                    UserDefaults.standard.set(coord.longitude, forKey: "longitude")
                                                    UserDefaults.standard.set(timeZone.identifier, forKey: "timezone")
                                                    
                                                    // Trigger refresh
                                                    prayerTimesVM.fetchPrayerTimes(
                                                        coordinates: prayerSettings.coordinates,
                                                        timezone: prayerSettings.timezone,
                                                        madhab: prayerSettings.madhab,
                                                        method: prayerSettings.calculationMethod
                                                    )
                                                    
                                                    // Schedule notifications
                                                    refreshManager.removeAllPendingNotifications()
                                                    refreshManager.scheduleMidnightRefresh(
                                                        coordinates: prayerSettings.coordinates,
                                                        timezone: prayerSettings.timezone,
                                                        scheduleNotifications: true,
                                                        madhab: prayerSettings.madhab,
                                                        method: prayerSettings.calculationMethod
                                                    )
                                                }
                                            }
                                            
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        } label: {
                                            Text(city.displayName)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    ForEach(allCities
                                        .filter { city in
                                            let matchesSearch =
                                            searchText.isEmpty ||
                                            city.name.lowercased().hasPrefix(searchText.lowercased()) ||
                                            city.displayName.lowercased().hasPrefix(searchText.lowercased())
                                            let isNotPreferred = !preferredCities.contains(where: { $0.name == city.name && $0.country == city.country })
                                            return matchesSearch && isNotPreferred
                                        }
                                        .sorted { $0.name.lowercased() < $1.name.lowercased() }
                                    ) { city in
                                        Button {
                                            // Update city name
                                            prayerSettings.selectedCity = city.name
                                            UserDefaults.standard.set(true, forKey: "hasManuallySelectedCity")
                                            showCitySearch = false
                                            searchText = ""

                                            // Geocode city to get coordinates + timezone
                                            let geocoder = CLGeocoder()
                                            geocoder.geocodeAddressString(city.displayName) { placemarks, error in
                                                guard let placemark = placemarks?.first,
                                                      let coord = placemark.location?.coordinate,
                                                      let timeZone = placemark.timeZone else {
                                                    print("❌ Failed to geocode \(city.displayName)")
                                                    return
                                                }

                                                DispatchQueue.main.async {
                                                    // Update prayerSettings
                                                    prayerSettings.coordinates = Coordinates(latitude: coord.latitude, longitude: coord.longitude)
                                                    prayerSettings.timezone = timeZone.identifier
                                                    UserDefaults.standard.set(coord.latitude, forKey: "latitude")
                                                    UserDefaults.standard.set(coord.longitude, forKey: "longitude")
                                                    UserDefaults.standard.set(timeZone.identifier, forKey: "timezone")

                                                    // Trigger refresh
                                                    prayerTimesVM.fetchPrayerTimes(
                                                        coordinates: prayerSettings.coordinates,
                                                        timezone: prayerSettings.timezone,
                                                        madhab: prayerSettings.madhab,
                                                        method: prayerSettings.calculationMethod
                                                    )

                                                    // Schedule notifications
                                                    refreshManager.removeAllPendingNotifications()
                                                    refreshManager.scheduleMidnightRefresh(
                                                        coordinates: prayerSettings.coordinates,
                                                        timezone: prayerSettings.timezone,
                                                        scheduleNotifications: true,
                                                        madhab: prayerSettings.madhab,
                                                        method: prayerSettings.calculationMethod
                                                    )
                                                }
                                            }

                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        } label: {
                                            Text(city.displayName)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .onChange(of: showCitySearch) { newValue in
                                    if newValue {
                                        scrollProxy = proxy
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                            proxy.scrollTo("top", anchor: .top)
                                        }
                                    }
                                }
                                .frame(height: 300)
                                .listStyle(PlainListStyle())
                            }
                        }
                        .background(Color(red: 0.0, green: 101/255, blue: 66/255))
                        .cornerRadius(12)
                        .padding()
                        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity),
                                                removal: .move(edge: .bottom).combined(with: .opacity)))
                        .animation(.easeInOut(duration: 0.3), value: showCitySearch)
                    }

                    ForEach(prayerTiles(from: model), id: \ .name) { prayer in
                        HStack {
                            Image(systemName: prayer.icon)
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading) {
                                Text(prayer.name)
                                    .font(.headline)
                                Text(prayer.time)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            // Logic for whent he user toggles notifications
                            Button(action: {
                                prayerTimesVM.notificationsEnabled[prayer.name]?.toggle()
                                if prayerTimesVM.notificationsEnabled[prayer.name] == false {
                                    print(prayer.name)
                                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(prayer.name)_\(prayerTimesVM.time(for: prayer.name))"])
                                }
                                else if prayerTimesVM.notificationsEnabled[prayer.name] == true {
                                    let formatter = DateFormatter()
                                    formatter.timeStyle = .short
                                    formatter.timeZone = TimeZone(identifier: model.options?.timezone ?? TimeZone.current.identifier)
                                    
                                    let prayerTime = prayerTimesVM.time(for: prayer.name)
                                    let body = "It's time to pray \(prayer.name) at \(formatter.string(from: prayerTime))"
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = prayer.name
                                    content.body = body
                                    content.sound = .default
                                    
                                    let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: prayerTime)
                                    let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                                    
                                    let request = UNNotificationRequest(identifier: "\(prayer.name)_\(prayerTime)", content: content, trigger: trigger)
                                    
                                    UNUserNotificationCenter.current().add(request)
                                }
                            }) {
                                Image(systemName: (prayerTimesVM.notificationsEnabled[prayer.name] ?? true) ? "bell.fill" : "bell.slash.fill")
                                    .foregroundColor(.blue)
                            }

                            Button(action: {
                                prayerTimesVM.audioEnabled[prayer.name]?.toggle()
                            }) {
                                Image(systemName: (prayerTimesVM.audioEnabled[prayer.name] ?? true) ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                } else {
                    ProgressView("Loading prayer times…")
                        .padding()
                        .onAppear(){
//                            print(prayerTimesModel!.fajr)
//                            print(prayerTimesModel!.dhuhr)
                            allCities = loadCitiesFromCSV()
                        }
                }
            }
        }
        .onAppear {
            print(prayerTimesModel.fajr)
            print(Date())
            print(prayerTimesModel.fajr == Date())
            allCities = loadCitiesFromCSV()
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .onReceive(locationManager.$location.compactMap { $0 }) { coords in
            let manuallySet = UserDefaults.standard.bool(forKey: "hasManuallySelectedCity")
            if manuallySet {
                print("🛑 Skipping location update — city was manually selected.")
                return
            }

            let location = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
            let geocoder = CLGeocoder()

            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first else { return }

                // Update city
                if let city = placemark.locality {
                    DispatchQueue.main.async {
                        prayerSettings.selectedCity = city
                        UserDefaults.standard.set(city, forKey: "selectedCity")
                    }
                }

                // Update coordinates
                DispatchQueue.main.async {
                    prayerSettings.coordinates = Coordinates(
                        latitude: coords.latitude,
                        longitude: coords.longitude
                    )
                    UserDefaults.standard.set(coords.latitude, forKey: "latitude")
                    UserDefaults.standard.set(coords.longitude, forKey: "longitude")
                }

                // Update timezone
                if let tz = placemark.timeZone {
                    DispatchQueue.main.async {
                        prayerSettings.timezone = tz.identifier
                        UserDefaults.standard.set(tz.identifier, forKey: "timezone")

                        // Fetch updated prayer times
                        prayerTimesVM.fetchPrayerTimes(
                            coordinates: prayerSettings.coordinates,
                            timezone: prayerSettings.timezone,
                            madhab: prayerSettings.madhab,
                            method: prayerSettings.calculationMethod
                        )

                        refreshManager.removeAllPendingNotifications()
                        refreshManager.scheduleMidnightRefresh(
                            coordinates: prayerSettings.coordinates,
                            timezone: prayerSettings.timezone,
                            scheduleNotifications: true,
                            madhab: prayerSettings.madhab,
                            method: prayerSettings.calculationMethod
                        )
                    }
                }
            }
        }


        .onAppear {
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                print("🔔 Pending Notifications: \(requests.count)")
                for request in requests {
                    print("🔹 Identifier: \(request.identifier)")
                    print("🔸 Title: \(request.content.title)")
                    print("🔸 Body: \(request.content.body)")
                    print("🔸 Trigger: \(String(describing: request.trigger))")
                    print("———————")
                }
            }
        }
        .alert(isPresented: $showPrayerAlert) {
            Alert(
                title: Text("It's time to pray \(currentPrayerName)"),
                message: Text("May Allah accept it."),
                dismissButton: .default(Text("Stop")) {
                    AudioManager.shared.stopAdhan()
                }
            )
        }
    }

    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    func prayerTiles(from model: PrayerTimesModel) -> [(name: String, time: String, icon: String)] {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.timeZone = TimeZone(identifier: model.options?.timezone ?? TimeZone.current.identifier)

        return [
            (Prayers.FAJR.rawValue, formatter.string(from: model.fajr), PrayerIcons.FAJR.rawValue),
            (Prayers.SUNRISE.rawValue, formatter.string(from: model.sunrise), PrayerIcons.SUNRISE.rawValue),
            (Prayers.DHUHR.rawValue, formatter.string(from: model.dhuhr), PrayerIcons.DHUHR.rawValue),
            (Prayers.ASR.rawValue, formatter.string(from: model.asr), PrayerIcons.ASR.rawValue),
            (Prayers.MAGHRIB.rawValue, formatter.string(from: model.maghrib), PrayerIcons.MAGHRIB.rawValue),
            (Prayers.ISHA.rawValue, formatter.string(from: model.isha), PrayerIcons.ISHA.rawValue),
            (Prayers.QIYAM.rawValue, formatter.string(from: model.qiyam), PrayerIcons.QIYAM.rawValue)
        ]
    }
    
//    func fetchPrayerTimesFromLocation(_ coord: Coordinates) {
//        prayerTimesHandler.getPrayerTimes(
//            for: coord,
//            date: Date(),
//            madhab: prayerSettings.madhab,
//            method: prayerSettings.calculationMethod,
//            timezone: prayerSettings.timezone
//        ) { result in
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let model):
//                    prayerTimesModel = model
//                    for name in Prayers.allCases {
//                        notificationsEnabled[name.rawValue] = true
//                        audioEnabled[name.rawValue] = true
//                    }
//                    
//                    adhanHandler.onAdhanTriggered = { prayerName in
//                        currentPrayerName = prayerName
//                        showPrayerAlert = true
//                    }
//                    let result = adhanHandler.checkIfShouldPlayAdhan(prayerTimes: model)
//                    if let prayer = result.prayer {
//                        if result.shouldPlay == true && audioEnabled[prayer.rawValue] == true {
//                            AudioManager.shared.playAdhan(prayer: prayer.rawValue)
//                        }
//                    }
//                    
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
//    }

    func schedulePrayerNotification(title: String, body: String, at date: Date, timezone: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: timezone) ?? .current

        let triggerDate = calendar.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: title, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error.localizedDescription)")
            }
        }
    }
    
    func getTimeZone(from coordinates: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, error in
            if let timeZone = placemarks?.first?.timeZone {
                completion(timeZone.description)
                print(timeZone.description)
            } else {
                print("❌ Failed to get timezone:", error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}
