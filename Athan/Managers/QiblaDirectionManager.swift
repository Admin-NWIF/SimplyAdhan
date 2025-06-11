//
//  QiblaDirectionManager.swift
//  Athan
//
//  Created by Usman Hasan on 5/25/25.
//

import Foundation
import CoreLocation
import Combine

class QiblaDirectionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var qiblaBearing: Double = 0

    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let new = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        if abs(new - heading) > 1 { // Ignores small fluctuations under 1°
            heading = new
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let loc = locations.last {
            currentLocation = loc
            qiblaBearing = calculateQiblaBearing(from: loc.coordinate)
        }
    }

    func calculateQiblaBearing(from coordinate: CLLocationCoordinate2D) -> Double {
        let kaabaLat = 21.4225 * .pi / 180
        let kaabaLon = 39.8262 * .pi / 180

        let userLat = coordinate.latitude * .pi / 180
        let userLon = coordinate.longitude * .pi / 180

        let deltaLon = kaabaLon - userLon

        let y = sin(deltaLon)
        let x = cos(userLat) * tan(kaabaLat) - sin(userLat) * cos(deltaLon)
        let bearing = atan2(y, x) * 180 / .pi
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
}
