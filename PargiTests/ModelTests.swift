//
//  PargiTests.swift
//  PargiTests
//
//  Simple tests to validate that serialisation of model objects works as expected
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import XCTest
import Cereal

class ModelTests: XCTestCase {
    
    // MARK: Zone
    func testZone() {
        let zone = self.exampleZone(seed: 30.0)
        
        do {
            let data = try CerealEncoder.data(withRoot: zone)
            let comparison: Zone = try CerealDecoder.rootCerealItem(with: data)
            
            XCTAssertTrue(self.equal(lhs: zone, rhs: comparison))
        } catch let error {
            XCTFail("Should not throw \(error)")
        }
    }
    
    // MARK: Provider
    
    func testProvider() {
        let zoneA = exampleZone(seed: 20.0)
        let zoneB = exampleZone(seed: 40.0)
        
        let provider = Provider(id: 1, name: "Provider", zones: [zoneA, zoneB], color: "AAA", beaconMajor: 0)
        
        do {
            let data = try CerealEncoder.data(withRoot: provider)
            let comparison: Provider = try CerealDecoder.rootCerealItem(with: data)
            
            XCTAssertTrue(self.equal(lhs: provider, rhs: comparison))
        } catch let error {
            XCTFail("Should not throw \(error)")
        }
    }
    
    // MARK: ZoneGroup
    
    func testZoneGroup() {
        let zoneA = exampleZone(seed: 20.0)
        let zoneB = exampleZone(seed: 40.0)
        
        let group = ZoneGroup(id: 1, reason: "geo", name: "Group", localizedName: "Locale Group", zones: [zoneA, zoneB])
        
        do {
            let data = try CerealEncoder.data(withRoot: group)
            let comparison: ZoneGroup = try CerealDecoder.rootCerealItem(with: data)
            
            XCTAssertTrue(self.equal(lhs: group, rhs: comparison))
        } catch let error {
            XCTFail("Should not throw \(error)")
        }
    }
    
    // MARK: Helpers
    
    func exampleZone(seed: Double) -> Zone {
        let tariffs = [
            Zone.Tariff(days: .Weekdays, periods: [Int(seed * 60): seed * 30, Int(seed * 20): seed * 15], minAmount: seed * 15),
            Zone.Tariff(days: .Weekend, periods: [Int(seed * 60): seed * 60, Int(seed * 20): seed * 30], minAmount: seed * 30)
        ]
        
        let regions = [
            Zone.Region(points: [Zone.Region.Location(latitude: seed * 30, longitude: seed * 30),
                                 Zone.Region.Location(latitude: seed * 30 + 0.1, longitude: seed * 30 + 0.1),
                                 Zone.Region.Location(latitude: seed * 30 - 01, longitude: seed * 30 - 0.1)]),
            Zone.Region(points: [Zone.Region.Location(latitude: seed * 20, longitude: seed * 20),
                                 Zone.Region.Location(latitude: seed * 20 + 0.3, longitude: seed * 20 + 0.3),
                                 Zone.Region.Location(latitude: seed * 20 + 0.4, longitude: seed * 20 + 0.4)],
                        interiorRegions: [
                            Zone.Region(points: [Zone.Region.Location(latitude: seed * 20 + 0.1, longitude: seed * 20 + 0.1),
                                                 Zone.Region.Location(latitude: seed * 20 + 0.2, longitude: seed * 20 + 0.2),
                                                 Zone.Region.Location(latitude: seed * 20 + 0.3, longitude: seed * 20 + 0.3)])
                ])
        ]
        
        return Zone(id: Int(seed), code: "seeded \(seed)", tariffs: tariffs, regions: regions, beaconMinor: Int(seed) * 2)
    }
    
    // MARK: Comparison
    
    func equal(lhs: ZoneGroup, rhs: ZoneGroup) -> Bool {
        if lhs.zones.count != rhs.zones.count {
            return false
        }
        
        for (idx, zone) in lhs.zones.enumerated() {
            if !self.equal(lhs: zone, rhs: rhs.zones[idx]) {
                return false
            }
        }
        
        if lhs.id != rhs.id {
            return false
        }
        
        if lhs.reason != rhs.reason {
            return false
        }
        
        if lhs.name != rhs.name {
            return false
        }
        
        if lhs.localizedName != rhs.localizedName {
            return false
        }
        
        return true
    }
    
    func equal(lhs: Provider, rhs: Provider) -> Bool {
        if lhs.zones.count != rhs.zones.count {
            return false
        }
        
        for (idx, zone) in lhs.zones.enumerated() {
            if !self.equal(lhs: zone, rhs: rhs.zones[idx]) {
                return false
            }
        }
        
        if lhs.id != rhs.id {
            return false
        }
        
        if lhs.name != rhs.name {
            return false
        }
        
        if lhs.color != rhs.color {
            return false
        }
        
        if lhs.beaconMajor != rhs.beaconMajor {
            return false
        }
        
        return true
    }
    
    func equal(lhs: Zone, rhs: Zone) -> Bool {
        if lhs.tariffs.count != rhs.tariffs.count {
            return false
        }
        
        if lhs.regions.count != rhs.regions.count {
            return false
        }
        
        if lhs.id != rhs.id {
            return false
        }
        
        if lhs.code != rhs.code {
            return false
        }
        
        if lhs.beaconMinor != rhs.beaconMinor {
            return false
        }
        
        for (idx, tariff) in lhs.tariffs.enumerated() {
            if !self.equal(lhs: tariff, rhs: rhs.tariffs[idx]) {
                return false
            }
        }
        
        for (idx, region) in lhs.regions.enumerated() {
            if !self.equal(lhs: region, rhs: rhs.regions[idx]) {
                return false
            }
        }
        
        return true
    }
    
    func equal(lhs: Zone.Tariff, rhs: Zone.Tariff) -> Bool {
        if lhs.days.rawValue != rhs.days.rawValue {
            return false
        }
        
        if lhs.periods != rhs.periods {
            return false
        }
        
        if lhs.periodStart != rhs.periodStart {
            return false
        }
        
        if lhs.periodEnd != rhs.periodEnd {
            return false
        }
        
        if lhs.freePeriod != rhs.freePeriod {
            return false
        }
        
        if lhs.minPeriod != rhs.minPeriod {
            return false
        }
        
        if lhs.minAmount != rhs.minAmount {
            return false
        }
        
        return true
    }
    
    func equal(lhs: Zone.Region, rhs: Zone.Region) -> Bool {
        if lhs.points.count != rhs.points.count {
            return false
        }
        
        if lhs.interiorRegions.count != rhs.interiorRegions.count {
            return false
        }
        
        for (idx, point) in lhs.points.enumerated() {
            if point.latitude != rhs.points[idx].latitude || point.longitude != rhs.points[idx].longitude {
                return false
            }
        }
        
        for (idx, region) in lhs.interiorRegions.enumerated() {
            if !self.equal(lhs: region, rhs: rhs.interiorRegions[idx]) {
                return false
            }
        }
        
        return true
    }
}
