import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    /// Pre-request authorization on app launch so the prompt appears early
    func requestAuthorization() {
        let status = manager.authorizationStatus
        print("[LocationManager] Current auth status: \(status.rawValue)")
        if status == .notDetermined {
            manager.requestAlwaysAuthorization()
        } else if status == .denied || status == .restricted {
            print("[LocationManager] Location access denied/restricted. Please enable in System Settings > Privacy > Location Services")
        }
    }

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion

        let status = manager.authorizationStatus
        print("[LocationManager] Requesting location, auth status: \(status.rawValue)")

        // Safety timeout — if location takes more than 10 seconds, continue without it
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, self.completion != nil else { return }
            print("[LocationManager] Timed out waiting for location")
            self.manager.stopUpdatingLocation()
            self.completion?(nil)
            self.completion = nil
        }
        self.timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)

        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
            // Will call locationManagerDidChangeAuthorization after user responds
        case .authorizedAlways, .authorized:
            // Use startUpdatingLocation instead of requestLocation — more reliable
            manager.startUpdatingLocation()
        default:
            print("[LocationManager] Not authorized (status \(status.rawValue)), skipping location")
            cancelTimeout()
            completion(nil)
            self.completion = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("[LocationManager] Auth changed to: \(status.rawValue)")
        if status == .authorizedAlways || status == .authorized {
            // Only request location if we have a pending completion
            if completion != nil {
                manager.startUpdatingLocation()
            }
        } else if status != .notDetermined {
            cancelTimeout()
            completion?(nil)
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Stop updates once we have a location (one-shot)
        manager.stopUpdatingLocation()
        cancelTimeout()

        if let location = locations.first {
            print("[LocationManager] Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
        completion?(locations.first)
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
        manager.stopUpdatingLocation()
        cancelTimeout()
        completion?(nil)
        completion = nil
    }

    private func cancelTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
}
