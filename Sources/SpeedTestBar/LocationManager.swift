import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion

        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            // Will call locationManagerDidChangeAuthorization after user responds
        case .authorizedAlways, .authorized:
            manager.requestLocation()
        default:
            completion(nil)
            self.completion = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorized {
            manager.requestLocation()
        } else if status != .notDetermined {
            completion?(nil)
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion?(locations.first)
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
        completion?(nil)
        completion = nil
    }
}
