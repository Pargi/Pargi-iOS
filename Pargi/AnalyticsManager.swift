//
//  AnalyticsManager.swift
//  Pargi
//
//  Helper for sending analytics info to backend
//
//  Created by Henri Normak on 10/03/2018.
//  Copyright © 2018 Henri Normak. All rights reserved.
//

import Foundation
import Networking
import CoreLocation

class AnalyticsManager {
    
    static let shared = AnalyticsManager()
    
    fileprivate var networking: Networking?
    fileprivate var formatter: ISO8601DateFormatter
    
    init() {
        self.formatter = ISO8601DateFormatter()
        self.formatter.formatOptions = [.withInternetDateTime]

        guard let info = Bundle.main.infoDictionary else {
            self.networking = nil
            return
        }
        
        // If environment is not correctly set up, we'll not have networking capabilities
        // however, the manager itself should still operate
        guard
            let baseURL = info["API_BASE_URL"] as? String,
            let apiKey = info["API_KEY"] as? String
        else {
            self.networking = nil
            return
        }
        
        // Make sure the API values are actually defined
        guard !baseURL.isEmpty, !apiKey.isEmpty else {
            self.networking = nil
            return
        }
        
        // Read app version
        guard let version = info["CFBundleShortVersionString"] as? String else {
            self.networking = nil
            return
        }

        
        let networking = Networking(baseURL: baseURL, configuration: .ephemeral)
        networking.setAuthorizationHeader(headerKey: "x-api-key", headerValue: apiKey)
        networking.headerFields = ["x-app-version": version]
        
        self.networking = networking
    }
    
    // MARK: API
    
    func trackParkingEvent(zone: Zone, start: Date, end: Date, coordinate: CLLocationCoordinate2D, deviceIdentifier: String) {
        guard let networking = self.networking else {
            // Simply ignore network requests
            return
        }
        
        let parameters: [String: Any] = [
            "zone": zone.code,
            "device": deviceIdentifier.lowercased(),
            "start": self.formatter.string(from: start),
            "end": self.formatter.string(from: end),
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude
        ]
        
        // We don't really care about the result, as the app does nothing with the information
        networking.post("/events", parameters: parameters) { _ in }
    }
}
