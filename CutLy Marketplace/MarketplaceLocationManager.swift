//
//  MarketplaceLocationManager.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 02/07/2026.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class MarketplaceLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    static let shared = MarketplaceLocationManager()

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var latitude: Double?
    @Published var longitude: Double?
    @Published var city: String = ""
    @Published var country: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoadingLocation = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    private override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 50
        authorizationStatus = manager.authorizationStatus
    }

    func requestLocation() {
        errorMessage = ""
        isLoadingLocation = true

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied, .restricted:
            isLoadingLocation = false
            errorMessage = "La localisation est désactivée. Activez-la dans les réglages pour rechercher autour de vous."

        @unknown default:
            isLoadingLocation = false
            errorMessage = "Impossible de vérifier l'autorisation de localisation."
        }
    }

    func startLiveTracking() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else {
            requestLocation()
            return
        }

        manager.startUpdatingLocation()
    }

    func stopLiveTracking() {
        manager.stopUpdatingLocation()
    }

    func distanceKm(from productLatitude: Double?, productLongitude: Double?) -> Double? {
        guard let productLatitude,
              let productLongitude,
              let currentLocation else {
            return nil
        }

        let productLocation = CLLocation(latitude: productLatitude, longitude: productLongitude)
        return currentLocation.distance(from: productLocation) / 1000
    }

    func isWithinRadius(
        productLatitude: Double?,
        productLongitude: Double?,
        radiusKm: Double
    ) -> Bool {
        guard radiusKm > 0 else { return true }
        guard let distance = distanceKm(
            from: productLatitude,
            productLongitude: productLongitude
        ) else { return false }

        return distance <= radiusKm
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus

            if manager.authorizationStatus == .authorizedWhenInUse ||
                manager.authorizationStatus == .authorizedAlways {
                manager.requestLocation()
            }

            if manager.authorizationStatus == .denied ||
                manager.authorizationStatus == .restricted {
                isLoadingLocation = false
                errorMessage = "Localisation refusée. Vous pouvez l’activer dans Réglages iPhone."
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            currentLocation = location
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            isLoadingLocation = false

            reverseGeocode(location)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            isLoadingLocation = false
            errorMessage = error.localizedDescription
        }
    }

    private func reverseGeocode(_ location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self else { return }

            Task { @MainActor in
                if let placemark = placemarks?.first {
                    self.city = placemark.locality ?? placemark.subAdministrativeArea ?? ""
                    self.country = placemark.country ?? ""
                }

                if let error {
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
}
