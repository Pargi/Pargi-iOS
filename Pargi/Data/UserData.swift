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
import Cereal

struct UserData {
    var licensePlateNumber: String?
    var otherLicensePlateNumbers: [String]
    
    var isParked: Bool = false
    var parkedAt: Date? = nil
    var currentParkedZone: Zone? = nil
    
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
            
            return UserData(licensePlateNumber: license, otherLicensePlateNumbers: otherLicenses, isParked: isParked, parkedAt: parkedAt, currentParkedZone: parkedZone)
        }
    }() {
        didSet {
            // Sync back to disk
            self.queue.async {
                if let data = try? CerealEncoder.data(withRoot: self.shared) {
                    try? data.write(to: self.userDataURL)
                }
            }
        }
    }
    
    // MARK: Background write
    
    private static let queue: DispatchQueue = DispatchQueue(label: "UserData.Sync")
}

extension UserData: CerealType {
    private enum Keys {
        static let licensePlateNumber = "licensePlateNumber"
        static let otherLicensePlateNumbers = "otherLicensePlateNumbers"
        static let isParked = "isParked"
        static let parkedAt = "parkedAt"
        static let currentParkedZone = "currentParkedZone"
    }
    
    init(decoder: Cereal.CerealDecoder) throws {
        let license: String? = try decoder.decode(key: Keys.licensePlateNumber)
        let otherLicenses: [String] = try decoder.decode(key: Keys.otherLicensePlateNumbers) ?? []
        let isParked: Bool = try decoder.decode(key: Keys.isParked)!
        let parkedAt: Date? = try decoder.decode(key: Keys.parkedAt)
        let currentParkedZone: Zone? = try decoder.decodeCereal(key: Keys.currentParkedZone)
        
        self.init(licensePlateNumber: license, otherLicensePlateNumbers: otherLicenses, isParked: isParked, parkedAt: parkedAt, currentParkedZone: currentParkedZone)
    }
    
    func encodeWithCereal(_ encoder: inout Cereal.CerealEncoder) throws {
        try encoder.encode(self.licensePlateNumber, forKey: Keys.licensePlateNumber)
        try encoder.encode(self.otherLicensePlateNumbers, forKey: Keys.otherLicensePlateNumbers)
        try encoder.encode(self.isParked, forKey: Keys.isParked)
        try encoder.encode(self.parkedAt, forKey: Keys.parkedAt)
        try encoder.encode(self.currentParkedZone, forKey: Keys.currentParkedZone)
    }
}
