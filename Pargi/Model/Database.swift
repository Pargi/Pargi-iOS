//
//  Database.swift
//  Pargi
//
//  Representation of the database of parking zones
//  Used to check whether an updated version exists in the cloud
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import Cereal

struct Database {
    let version: SemanticVersion
    let date: Date
    let hash: String
    
    // Data
    let providers: [Provider]
    let groups: [ZoneGroup]
    
    // Returns all zones, ordered by their code
    var zones: [Zone] {
        get {
            return self.providers.flatMap({ $0.zones }).sorted(by: { $0.code.compare($1.code, options: .numeric, range: nil, locale: nil) == .orderedAscending })
        }
    }
    
    func provider(for zone: Zone) -> Provider? {
        return self.providers.first { (provider) -> Bool in
            return provider.zones.contains(where: { (comp) -> Bool in
                return comp == zone
            })
        }
    }
}

extension Database: CustomStringConvertible {
    var description: String {
        return "Database(version: \(self.version.rawValue), date: \(self.date), hash: \(self.hash), providers: \(self.providers.count), groups: \(self.groups.count))"
    }
}

// Barebones semver implementation
struct SemanticVersion: ExpressibleByStringLiteral {
    let rawValue: String
    
    init(stringLiteral: StringLiteralType) {
        self.rawValue = stringLiteral
    }
    
    init(unicodeScalarLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    init(extendedGraphemeClusterLiteral value: String) {
        self.init(stringLiteral: value)
    }
    
    static func ==(left: SemanticVersion, right: SemanticVersion) -> Bool {
        return left.rawValue == right.rawValue
    }
    
    static func >=(left: SemanticVersion, right: SemanticVersion) -> Bool {
        return [ComparisonResult.orderedSame, ComparisonResult.orderedDescending].contains(left.rawValue.compare(right.rawValue, options: .numeric, range: nil, locale: nil))
    }
    
    static func <=(left: SemanticVersion, right: SemanticVersion) -> Bool {
        return [ComparisonResult.orderedSame, ComparisonResult.orderedAscending].contains(left.rawValue.compare(right.rawValue, options: .numeric, range: nil, locale: nil))
    }
    
    static func >(left: SemanticVersion, right: SemanticVersion) -> Bool {
        return left.rawValue.compare(right.rawValue, options: .numeric, range: nil, locale: nil) == .orderedDescending
    }
    
    static func <(left: SemanticVersion, right: SemanticVersion) -> Bool {
        return left.rawValue.compare(right.rawValue, options: .numeric, range: nil, locale: nil) == .orderedAscending
    }
}

// MARK: Cereal

extension Database: CerealType {
    private enum Keys {
        static let version = "version"
        static let date = "date"
        static let hash = "hash"
        static let providers = "providers"
        static let groups = "groups"
    }
    
    init(decoder: Cereal.CerealDecoder) throws {
        let version: SemanticVersion = try decoder.decodeCereal(key: Keys.version)!
        let date: Date = try decoder.decode(key: Keys.date)!
        let hash: String = try decoder.decode(key: Keys.hash)!
        let providers: [Provider] = try decoder.decodeCereal(key: Keys.providers)!
        let groups: [ZoneGroup] = try decoder.decodeCereal(key: Keys.groups)!
        
        self.init(version: version, date: date, hash: hash, providers: providers, groups: groups)
    }
    
    func encodeWithCereal(_ encoder: inout Cereal.CerealEncoder) throws {
        try encoder.encode(self.version, forKey: Keys.version)
        try encoder.encode(self.date, forKey: Keys.date)
        try encoder.encode(self.hash, forKey: Keys.hash)
        try encoder.encode(self.providers, forKey: Keys.providers)
        try encoder.encode(self.groups, forKey: Keys.groups)
    }
}

extension SemanticVersion: CerealType {
    init(decoder: Cereal.CerealDecoder) throws {
        self.rawValue = try decoder.decode(key: "rawValue")!
    }

    func encodeWithCereal(_ encoder: inout Cereal.CerealEncoder) throws {
        try encoder.encode(self.rawValue, forKey: "rawValue")
    }
}
