//
//  Provider.swift
//  Pargi
//
//  Model representation of a parking service provider
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import Cereal

struct Provider {
    let id: Int
    let name: String
    let zones: [Zone]
    
    // Hexadecimal color
    let color: String
    
    // Unused
    let beaconMajor: Int?
    
    init(id: Int, name: String, zones: [Zone], color: String, beaconMajor: Int? = nil) {
        self.id = id
        self.name = name
        self.color = color
        self.beaconMajor = beaconMajor
        self.zones = zones
    }
}

extension Provider: CustomStringConvertible {
    var description: String {
        return "Provider(id: \(self.id), name: \(self.name), color: \(self.color), zones: \(self.zones.count))"
    }
}

// MARK: Cereal

extension Provider: CerealType {
    private struct Keys {
        static let id = "id"
        static let name = "name"
        static let zones = "zones"
        static let color = "color"
        static let beaconMajor = "beaconMajor"
    }
    
    init(decoder: Cereal.CerealDecoder) throws {
        let id: Int = try decoder.decode(key: Keys.id)!
        let name: String = try decoder.decode(key: Keys.name)!
        let color: String = try decoder.decode(key: Keys.color)!
        let beaconMajor: Int? = try decoder.decode(key: Keys.beaconMajor)
        let zones: [Zone] = try decoder.decodeCereal(key: Keys.zones)!
        
        self.init(id: id, name: name, zones: zones, color: color, beaconMajor: beaconMajor)
    }
    
    func encodeWithCereal(_ encoder: inout Cereal.CerealEncoder) throws {
        try encoder.encode(self.id, forKey: Keys.id)
        try encoder.encode(self.name, forKey: Keys.name)
        try encoder.encode(self.color, forKey: Keys.color)
        try encoder.encode(self.beaconMajor, forKey: Keys.beaconMajor)
        try encoder.encode(self.zones, forKey: Keys.zones)
    }
}
