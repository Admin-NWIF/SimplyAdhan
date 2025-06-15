//
//  LocationManager.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var error: Error?
    @Published var hasLocationPermission: Bool = false

    override init() {
        super.init()
        manager.delegate = self
        requestAuthorization()
        startUpdatingLocation()
    }

    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    // MARK: - Delegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let lastLocation = locations.last {
            location = lastLocation.coordinate
            print("Got location: \(location!)")
        }
        stopUpdatingLocation() // stop after getting one location
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = error
        stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationPermission = true
            UserDefaults.standard.set(true, forKey: "grantedLocationPerms")
        default:
            hasLocationPermission = false
        }
    }
}
