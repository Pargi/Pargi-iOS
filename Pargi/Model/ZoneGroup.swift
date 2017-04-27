//
//  ZoneGroup.swift
//  Pargi
//
//  Model representation for a group of zones
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import Cereal

struct ZoneGroup {
    let id: Int
    let reason: String
    let name: String
    let localizedName: String?
    
    let zones: [Zone]
    
    
    init(id: Int, reason: String, name: String, localizedName: String? = nil, zones: [Zone]) {
        self.id = id
        self.reason = reason
        self.name = name
        self.localizedName = localizedName
        self.zones = zones
    }
}

extension ZoneGroup: CustomStringConvertible {
    var description: String {
        return "ZoneGroup(id: \(self.id), reason: \(self.reason), name: \(self.name), zones: \(self.zones.count))"
    }
}

// MARK: Cereal

extension ZoneGroup: CerealType {
    private struct Keys {
        static let id = "id"
        static let reason = "reason"
        static let name = "name"
        static let localizedName = "localizedName"
        static let zones = "zones"
    }
    
    init(decoder: CerealDecoder) throws {
        let id: Int = try decoder.decode(key: Keys.id)!
        let reason: String = try decoder.decode(key: Keys.reason)!
        let name: String = try decoder.decode(key: Keys.name)!
        let localizedName: String? = try decoder.decode(key: Keys.localizedName)
        let zones: [Zone] = try decoder.decodeCereal(key: Keys.zones)!
        
        self.init(id: id, reason: reason, name: name, localizedName: localizedName, zones: zones)
    }
    
    func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.id, forKey: Keys.id)
        try encoder.encode(self.reason, forKey: Keys.reason)
        try encoder.encode(self.name, forKey: Keys.name)
        try encoder.encode(self.localizedName, forKey: Keys.localizedName)
        try encoder.encode(self.zones, forKey: Keys.zones)
    }
}
