import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: ((CLLocation?) -> Void)?
    private var timeoutWorkItem: DispatchWorkItem?
    
    private let timeouts: [TimeInterval] = [10.0, 20.0, 30.0]
    private var currentAttempt = 0

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
        self.currentAttempt = 0

        let status = manager.authorizationStatus
        print("[LocationManager] Requesting location, auth status: \(status.rawValue)")

        switch status {
        case .notDetermined:
            manager.requestAlwaysAuthorization()
            // Will call locationManagerDidChangeAuthorization after user responds
        case .authorizedAlways, .authorized:
            startAttempt()
        default:
            print("[LocationManager] Not authorized (status \(status.rawValue)), skipping location")
            cancelTimeout()
            completion(nil)
            self.completion = nil
        }
    }

    private func startAttempt() {
        cancelTimeout()
        
        guard currentAttempt < timeouts.count else {
            print("[LocationManager] Exhausted all attempts. Falling back.")
            finishWithFallback()
            return
        }
        
        let timeoutDuration = timeouts[currentAttempt]
        print("[LocationManager] Starting attempt \(currentAttempt + 1) with timeout \(timeoutDuration)s")
        
        let timeout = DispatchWorkItem { [weak self] in
            guard let self = self, self.completion != nil else { return }
            print("[LocationManager] Attempt \(self.currentAttempt + 1) timed out.")
            self.manager.stopUpdatingLocation()
            self.currentAttempt += 1
            self.startAttempt() // Try the next attempt
        }
        self.timeoutWorkItem = timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + timeoutDuration, execute: timeout)
        
        manager.startUpdatingLocation()
    }
    
    private func finishWithFallback() {
        if let lastKnown = manager.location {
            print("[LocationManager] Fallback: Using last known location")
            completion?(lastKnown)
        } else {
            print("[LocationManager] Fallback: No cached location available")
            completion?(nil)
        }
        completion = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("[LocationManager] Auth changed to: \(status.rawValue)")
        if status == .authorizedAlways || status == .authorized {
            // Only request location if we have a pending completion
            if completion != nil {
                startAttempt()
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
        
        // If we hit an error, retry if we have attempts left, else fallback
        currentAttempt += 1
        if currentAttempt < timeouts.count {
            startAttempt()
        } else {
            finishWithFallback()
        }
    }

    private func cancelTimeout() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }
}
