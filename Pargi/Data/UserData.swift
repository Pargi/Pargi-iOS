//
//  UserData.swift
//  Pargi
//
//  Storing user preferences/data, while also
//  giving access to legacy data from old Pargi versions
//
//  Created by Henri Normak on 01/06/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import CoreLocation
import Cereal

struct UserData {
    // Notification, fired when a change is made to the shared user data
    // object of the notification is the (now updated) shared user data
    static let UpdatedNotification = Notification.Name("UserDataUpdatedNotification")
    
    // User info key for the UpdatedNotification containing the previous UserData value
    static let OldUserDataKey = "OldUserDataKey"

    var deviceIdentifier: String
    var licensePlateNumber: String?
    var otherLicensePlateNumbers: [String]
    
    var isParked: Bool = false
    var parkedAt: Date? = nil
    var currentParkedZone: Zone? = nil
    var currentParkedCoordinate: CLLocationCoordinate2D? = nil
    
    private static let userDataURL: URL = {
        let base = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return base.appendingPathComponent("user")
    }()

    static var shared: UserData = {
        let url = UserData.userDataURL
        do {
            let data = try Data(contentsOf: url)
            let value: UserData = try CerealDecoder.rootCerealItem(with: data)
            return value
        } catch {
            // Swallow the error, fall back to legacy user data
            // or if not present to a default set
            // Keys are from old code (i.e legacy)
            let userDefaults = UserDefaults.standard
            let license = userDefaults.string(forKey: "Car Number") ?? userDefaults.string(forKey: "PargiCurrentCar")
            let otherLicenses: [String] = userDefaults.array(forKey: "Recent plates") as? [String] ?? []
            let isParked = userDefaults.bool(forKey: "isParked")
            let parkedAt = userDefaults.value(forKey: "PargiStartDate") as? Date
            
            let parkedZone: Zone? = {
                if let parkedZoneCode = userDefaults.string(forKey: "PargiCurrentZone") {
                    return ApplicationData.currentDatabase.zone(forCode: parkedZoneCode)
                }
                
                return nil
            }()
            
            // Generate a new UUID for the device (just a random UUID)
            let identifier = UUID().uuidString
            
            return UserData(deviceIdentifier: identifier, licensePlateNumber: license, otherLicensePlateNumbers: otherLicenses, isParked: isParked, parkedAt: parkedAt, currentParkedZone: parkedZone, currentParkedCoordinate: nil)
        }
    }() {
        didSet {
            // Sync back to disk
            self.queue.async {
                if let data = try? CerealEncoder.data(withRoot: self.shared) {
                    try? data.write(to: self.userDataURL)
                }
            }
            
            // Fire off a notification
            NotificationCenter.default.post(name: UserData.UpdatedNotification, object: self.shared, userInfo: [UserData.OldUserDataKey: oldValue])
        }
    }
    
    // Convenience
    
    mutating func startParking(withZone zone: Zone, andCoordinate coordinate: CLLocationCoordinate2D? = nil) {
        self.isParked = true
        self.currentParkedZone = zone
        self.currentParkedCoordinate = coordinate
        self.parkedAt = Date()
    }
    
    mutating func endParking() {
        self.isParked = false
        self.currentParkedZone = nil
        self.currentParkedCoordinate = nil
        self.parkedAt = nil
    }
    
    // MARK: Background write
    
    private static let queue: DispatchQueue = DispatchQueue(label: "UserData.Sync")
}

extension UserData: CerealType {
    private enum Keys {
        static let deviceIdentifier = "deviceIdentifier"
        static let licensePlateNumber = "licensePlateNumber"
        static let otherLicensePlateNumbers = "otherLicensePlateNumbers"
        static let isParked = "isParked"
        static let parkedAt = "parkedAt"
        static let currentParkedZone = "currentParkedZone"
        static let currentParkedCoordinate = "currentParkedCoordinate"
    }
    
    init(decoder: Cereal.CerealDecoder) throws {
        let deviceIdentifier: String = try decoder.decode(key: Keys.deviceIdentifier) ?? UUID().uuidString
        let license: String? = try decoder.decode(key: Keys.licensePlateNumber)
        let otherLicenses: [String] = try decoder.decode(key: Keys.otherLicensePlateNumbers) ?? []
        let isParked: Bool = try decoder.decode(key: Keys.isParked)!
        let parkedAt: Date? = try decoder.decode(key: Keys.parkedAt)
        let currentParkedZone: Zone? = try decoder.decodeCereal(key: Keys.currentParkedZone)
        let currentParkedCoordinate: CLLocationCoordinate2D? = try decoder.decodeCereal(key: Keys.currentParkedCoordinate)
        
        self.init(deviceIdentifier: deviceIdentifier, licensePlateNumber: license, otherLicensePlateNumbers: otherLicenses, isParked: isParked, parkedAt: parkedAt, currentParkedZone: currentParkedZone, currentParkedCoordinate: currentParkedCoordinate)
    }
    
    func encodeWithCereal(_ encoder: inout Cereal.CerealEncoder) throws {
        try encoder.encode(self.deviceIdentifier, forKey: Keys.deviceIdentifier)
        try encoder.encode(self.licensePlateNumber, forKey: Keys.licensePlateNumber)
        try encoder.encode(self.otherLicensePlateNumbers, forKey: Keys.otherLicensePlateNumbers)
        try encoder.encode(self.isParked, forKey: Keys.isParked)
        try encoder.encode(self.parkedAt, forKey: Keys.parkedAt)
        try encoder.encode(self.currentParkedZone, forKey: Keys.currentParkedZone)
        try encoder.encode(self.currentParkedCoordinate, forKey: Keys.currentParkedCoordinate)
    }
}

// Add Cereal support to CLLocationCoordinate2D
extension CLLocationCoordinate2D: CerealType {
    private struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
    }
    
    public init(decoder: CerealDecoder) throws {
        let latitude: CLLocationDegrees = try decoder.decode(key: Keys.latitude)!
        let longitude: CLLocationDegrees = try decoder.decode(key: Keys.longitude)!
        
        self.init(latitude: latitude, longitude: longitude)
    }
    
    public func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.latitude, forKey: Keys.latitude)
        try encoder.encode(self.longitude, forKey: Keys.longitude)
    }
}
