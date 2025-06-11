//
//  PrayerTimesHandler.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//
import Foundation
import CoreLocation
import Adhan
import SwiftUICore

struct PrayerTimesHandler {
    init() {}

    func getPrayerTimes(for coordinates: Coordinates, date: Date, madhab: Madhab, method: String, timezone: String, completion: @escaping (Result<PrayerTimesModel, Error>) -> Void) {
        
        // 1. Map method string to Adhan CalculationMethod
        let methodMap: [String: CalculationMethod] = [
            "Muslim World League": .muslimWorldLeague,
            "Egyptian": .egyptian,
            "Karachi": .karachi,
            "Umm Al-Qura": .ummAlQura,
            "Dubai": .dubai,
            "Moonsighting Committee": .moonsightingCommittee,
            "ISNA": .northAmerica,
            "Kuwait": .kuwait,
            "Qatar": .qatar,
            "Singapore": .singapore,
            "Turkey": .turkey,
            "Tehran": .tehran
        ]
        
        guard let methodEnum = methodMap[method] else {
            completion(.failure(NSError(domain: "InvalidMethod", code: 1)))
            return
        }

        // 2. Set coordinates
        let adhanCoords = Adhan.Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)

        // 3. Set calculation parameters
        var params = methodEnum.params
        params.madhab = madhab

        // 4. Extract just the .year, .month, .day for the prayer day
        let timeZone = TimeZone(identifier: timezone) ?? .current
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: timeZone, from: date)
        let dayComponents = DateComponents(year: components.year, month: components.month, day: components.day)

        // 5. Calculate prayer times
        guard let adhanPrayerTimes = PrayerTimes(coordinates: adhanCoords, date: dayComponents, calculationParameters: params) else {
            completion(.failure(NSError(domain: "CalculationFailed", code: 2)))
            return
        }

        // 6. Use UTC dates directly; format later in correct timezone
        let fajr = adhanPrayerTimes.fajr
        let sunrise = adhanPrayerTimes.sunrise
        let dhuhr = adhanPrayerTimes.dhuhr
        let asr = adhanPrayerTimes.asr
        let maghrib = adhanPrayerTimes.maghrib
        let isha = adhanPrayerTimes.isha

        // Qiyam (midpoint between isha and fajr)
        let fajrAdjusted = fajr < isha ? Calendar.current.date(byAdding: .day, value: 1, to: fajr) ?? fajr : fajr
        let qiyam = isha.addingTimeInterval(fajrAdjusted.timeIntervalSince(isha) / 2)

        let model = PrayerTimesModel(
            date: date,
            fajr: fajr,
            sunrise: sunrise,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            qiyam: qiyam,
            coordinates: coordinates,
            options: Options(timezone: timezone, method: method)
        )

        completion(.success(model))

    }

    
    func getCoordinatesForCityFromSearch(forCity city: String, completion: @escaping (Result<Coordinates, Error>) -> Void) {
        let query = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://nominatim.openstreetmap.org/search?q=\(query)&format=json&limit=1"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0)))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("AthanApp/1.0 (usman@athan.dev)", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0)))
                return
            }
            
            do {
                let results = try JSONDecoder().decode([NominatimResult].self, from: data)
                guard let result = results.first,
                      let lat = Double(result.lat),
                      let lon = Double(result.lon) else {
                    completion(.failure(NSError(domain: "NoResults", code: 0)))
                    return
                }
                
                completion(.success(Coordinates(latitude: lat, longitude: lon)))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    func getCoordinatesFromDeviceLocation(completion: @escaping (Result<Coordinates, Error>) -> Void) {
        class LocationDelegate: NSObject, CLLocationManagerDelegate {
            let completion: (Result<Coordinates, Error>) -> Void
            
            init(completion: @escaping (Result<Coordinates, Error>) -> Void) {
                self.completion = completion
            }
            
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                if let location = locations.first {
                    let coords = Coordinates(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
                    completion(.success(coords))
                    manager.stopUpdatingLocation()
                }
            }
            
            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                completion(.failure(error))
            }
        }
        
        let manager = CLLocationManager()
        let delegate = LocationDelegate(completion: completion)
        manager.delegate = delegate
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        
        // To persist delegate, you may need to store it in a property in a view model or similar.
    }
}
