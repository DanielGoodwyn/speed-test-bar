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
        if manager.authorizationStatus == .notDetermined {
            manager.requestAlwaysAuthorization()
        }
    }

    func requestLocation(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion

        // Safety timeout — if location takes more than 10 seconds, continue without it
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, self.completion != nil else { return }
            print("[LocationManager] Timed out waiting for location")
            self.completion?(nil)
            self.completion = nil
        }
        self.timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)

        let status = manager.authorizationStatus
        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
            // Will call locationManagerDidChangeAuthorization after user responds
        case .authorizedAlways, .authorized:
            manager.requestLocation()
        default:
            // Denied or restricted — try requesting again in case user changed settings
            print("[LocationManager] Status: \(status.rawValue) — requesting without location")
            cancelTimeout()
            completion(nil)
            self.completion = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorized {
            // Only request location if we have a pending completion
            if completion != nil {
                manager.requestLocation()
            }
        } else if status != .notDetermined {
            cancelTimeout()
            completion?(nil)
            completion = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        cancelTimeout()
        completion?(locations.first)
        completion = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] Error: \(error.localizedDescription)")
        cancelTimeout()
        completion?(nil)
        completion = nil
    }

    private func cancelTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
}
