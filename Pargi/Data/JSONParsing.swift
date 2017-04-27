//
//  JSONParsing.swift
//  Pargi
//
//  Functions for parsing JSON into model objects
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation

extension Database {
    init?(dictionary: [String: Any]) {
        guard let version = dictionary["version"] as? String,
            let date = dictionary["date"] as? TimeInterval,
            let hash = dictionary["hash"] as? String else {
                return nil
        }
        
        self.version = SemanticVersion(stringLiteral: version)
        self.date = Date(timeIntervalSince1970: date)
        self.hash = hash
        
        guard let data = dictionary["data"] as? [String: [Any]],
            let providers = data["providers"] as? [[String: Any]],
            let zones = data["zones"] as? [[String: Any]] else {
            return nil
        }
        
        // Parse zones first, group them by their provider into a dictionary
        var keyedZones = [Int: [Zone]]()
        for dict in zones {
            var provider = 0
            guard let zone = Zone(dictionary: dict, providerId: &provider) else {
                continue
            }
            
            if keyedZones[provider] != nil {
                keyedZones[provider]! += [zone]
            } else {
                keyedZones[provider] = [zone]
            }
        }
                
        let allZones = Array(Array(keyedZones.values).joined())
        
        // Parse individual pieces of data
        self.providers = providers.flatMap({ Provider(dictionary: $0, zones: keyedZones) })

        if let groups = data["groups"] as? [[String: Any]] {
            self.groups = groups.flatMap({ ZoneGroup(dictionary: $0, zones: allZones) })
        } else {
            self.groups = []
        }
    }
}

fileprivate extension Provider {
    // Also takes a pool of zones, from which the provider can pick
    init?(dictionary: [String: Any], zones: [Int: [Zone]]) {
        guard let id = dictionary["id"] as? Int, let name = dictionary["name"] as? String, let color = dictionary["color"] as? String else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.color = color
        
        self.beaconMajor = dictionary["beacon-major"] as? Int
        self.zones = zones[self.id] ?? []
    }
}

fileprivate extension Zone {
    init?(dictionary: [String: Any], providerId: inout Int) {
        guard let id = dictionary["id"] as? Int, let code = dictionary["code"] as? String else {
            return nil
        }
        
        if let provider = dictionary["provider"] as? Int {
            providerId = provider
        }
        
        self.id = id
        self.code = code
        
        // Regions
        if let regions = dictionary["regions"] as? [[String: Any]] {
            self.regions = regions.flatMap(Zone.Region.init)
        } else if let region = dictionary["regions"] as? [String: Any] {
            self.regions = [Zone.Region.init(dictionary: region)].flatMap({ $0 })
        } else {
            return nil
        }
        
        // Tariff
        if let tariffs = dictionary["tariffs"] as? [[String: Any]] {
            self.tariffs = tariffs.flatMap(Zone.Tariff.init)
        } else {
            self.tariffs = []
        }
        
        self.beaconMinor = dictionary["beacon-minor"] as? Int
    }
}

fileprivate extension Zone.Tariff {
    init?(dictionary: [String: Any]) {
        guard let days = dictionary["days"] as? Int, let periods = dictionary["periods"] as? [String: Double] else {
            return nil
        }
        
        self.days = Zone.Tariff.Day(rawValue: days)
        self.periods = periods.map(transform: { (Int($0)!, $1) })
        
        self.periodStart = dictionary["start"] as? Int
        self.periodEnd = dictionary["end"] as? Int
        self.freePeriod = dictionary["free-period"] as? Int
        self.minPeriod = dictionary["min-period"] as? Int
        self.minAmount = dictionary["min-amount"] as? Double
    }
}

fileprivate extension Zone.Region {
    init?(dictionary: [String: Any]) {
        guard let points = dictionary["points"] as? [[Double]] else {
            return nil
        }
        
        // Validate all points (no shenanigans with less than 2 numbers or anything)
        guard points.flatMap({ $0.count != 2 ? $0 : nil }).count == 0 else {
            return nil
        }
        
        self.points = points.map({ Zone.Region.Location(latitude: $0[0], longitude: $0[1]) })
        
        if let interiorRegions = dictionary["interiorRegions"] as? [[String: Any]] {
            self.interiorRegions = interiorRegions.flatMap(Zone.Region.init)
        } else {
            self.interiorRegions = []
        }
    }
}

fileprivate extension ZoneGroup {
    // Also takes a pool of zones, from which the group can be formed (based on IDs provided in the dict)
    init?(dictionary: [String: Any], zones: [Zone]) {
        guard let id = dictionary["id"] as? Int, let reason = dictionary["reason"] as? String, let name = dictionary["name"] as? String else {
            return nil
        }
        
        self.id = id
        self.reason = reason
        self.name = name
        self.localizedName = dictionary["localized-name"] as? String
        
        guard let zoneIDs = dictionary["zones"] as? [Int] else {
            return nil
        }
        
        self.zones = zones.filter({ zoneIDs.contains($0.id) })
    }
}

// MARK: Helper

fileprivate extension Dictionary {
    func map<K: Hashable, V> (transform: (Key, Value) -> (K, V)) -> Dictionary<K, V> {
        var results: Dictionary<K, V> = [:]
        for k in self.keys {
            if let value = self[ k ] {
                let (u, w) = transform(k, value)
                results.updateValue(w, forKey: u)
            }
        }
        return results
    }
}
