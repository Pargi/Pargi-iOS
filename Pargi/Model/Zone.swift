//
//  Zone.swift
//  Pargi
//
//  Model representation of a single parking zone
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import Cereal

struct Zone {
    let id: Int
    let code: String
    let tariffs: [Tariff]
    let regions: [Region]
    
    // Unused
    let beaconMinor: Int?
    
    init(id: Int, code: String, tariffs: [Tariff], regions: [Region], beaconMinor: Int? = nil) {
        self.id = id
        self.code = code
        self.tariffs = tariffs
        self.regions = regions
        self.beaconMinor = beaconMinor
    }
    
    // Inner types
    struct Region {
        struct Location {
            let latitude: Double
            let longitude: Double
        }
        
        let points: [Location]
        
        // "Holes", regions that are within the main area, but should not be actually included
        let interiorRegions: [Region]
        
        init(points: [Location], interiorRegions: [Region] = []) {
            self.points = points
            self.interiorRegions = interiorRegions
        }
    }
    
    struct Tariff {
        struct Day: OptionSet {
            let rawValue: Int
            
            init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            init?(calendarValue: Int) {
                switch calendarValue {
                case 2:
                    self = .Monday
                case 3:
                    self = .Tuesday
                case 4:
                    self = .Wednesday
                case 5:
                    self = .Thursday
                case 6:
                    self = .Friday
                case 7:
                    self = .Saturday
                case 1:
                    self = .Sunday
                default:
                    return nil
                }
            }
            
            static let Monday = Day(rawValue: 1)
            static let Tuesday = Day(rawValue: 2)
            static let Wednesday = Day(rawValue: 4)
            static let Thursday = Day(rawValue: 8)
            static let Friday = Day(rawValue: 16)
            static let Saturday = Day(rawValue: 32)
            static let Sunday = Day(rawValue: 64)
            
            static let Empty: Day = []
            static let All: Day = Weekdays.union(Weekend)
            static let Weekdays: Day = [Monday, Tuesday, Wednesday, Thursday, Friday]
            static let Weekend: Day = [Saturday, Sunday]
        }
        
        let days: Day
        
        // Seconds: Cents
        let periods: [Int: Double]
        
        // Both in seconds (within a day, so between 0 and 86400)
        let periodStart: Int?
        let periodEnd: Int?
        
        // Both in seconds
        let freePeriod: Int?
        let minPeriod: Int?
        
        // In cents
        let minAmount: Double?
        
        init(days: Day, periods: [Int: Double], periodStart: Int? = nil, periodEnd: Int? = nil, freePeriod: Int? = nil, minPeriod: Int? = nil, minAmount: Double? = nil) {
            self.days = days
            self.periods = periods
            self.periodStart = periodStart
            self.periodEnd = periodEnd
            self.freePeriod = freePeriod
            self.minPeriod = minPeriod
            self.minAmount = minAmount
        }
    }
    
    // MARK: Price calculation
    
    ///
    /// Estimated price for parking in said zone
    ///
    /// - parameters:
    ///     - from: Start date for parking
    ///     - to: End date for parking (should be later than from)
    ///     - calendar: Optional calendar to do the calculations with
    ///
    /// - returns: Estimated cost of parking in the zone, in cents, as well as the actual time the cost will cover
    ///
    func estimatedPrice(from: Date, to: Date = Date(timeIntervalSinceNow: 0), calendar: Calendar = Calendar.autoupdatingCurrent) -> (cost: Double, from: Date, to: Date) {
        // Three ways to calculate the estimated price
        // A - Using only the biggest unit of time to cover the period
        // B - Using only the smallest unit of time to cover the period
        // C - Using greedy fit to cover the period
        typealias Estimate = (algorithm: Zone.Tariff.Algorithm, cost: Double, to: Date)
        var estimates = [Estimate(.minimum, 0, to), Estimate(.maximum, 0, to), Estimate(.greedy, 0, to)]
        
        for tariff in self.tariffs {
            let interval = tariff.interval(from: from, to: to, calendar: calendar)
            
            for (idx, var estimate) in estimates.enumerated() {
                guard let (paidInterval, cost) = tariff.estimatedCost(interval: interval, algorithm: estimate.algorithm) else {
                    continue
                }
                
                estimate.cost += cost
                estimate.to = estimate.to.laterDate(to.addingTimeInterval(paidInterval - interval))
                
                estimates[idx] = estimate
            }
        }
        
        let best = estimates.sorted(by: { $0.cost < $1.cost }).first!
        return (best.cost, from, best.to)
    }
}

private extension Zone.Tariff {
    enum Algorithm {
        case minimum
        case maximum
        case greedy
    }
    
    func interval(from: Date, to: Date, calendar: Calendar = Calendar.autoupdatingCurrent) -> TimeInterval {
        var cursor = calendar.startOfDay(for: from)
        var interval: TimeInterval = 0
        
        // Helpers
        let start = TimeInterval(self.periodStart ?? 0)
        
        // Seeking to the next day
        var components = DateComponents()
        (components.hour, components.minute, components.second) = (0, 0, 0)
        
        // In order to calculate the interval:
        // - Move day by day, only taking into account days that are covered by us
        // - Within the day, only take into account the time that is covered by us
        // - Repeat until the time span is covered
        
        while cursor.compare(to) == .orderedAscending {
            guard let day = Day(calendarValue: calendar.component(.weekday, from: cursor)), self.days.contains(day) else {
                cursor = calendar.nextDate(after: cursor, matching: components, matchingPolicy: .nextTime)!
                continue
            }
            
            let intervalStart = cursor.addingTimeInterval(start).laterDate(from)
            guard intervalStart.earlierDate(to) == intervalStart else {
                cursor = to
                continue
            }
            
            var intervalEnd: Date
            if let periodEnd = self.periodEnd {
                intervalEnd = cursor.addingTimeInterval(TimeInterval(periodEnd))
            } else {
                intervalEnd = calendar.nextDate(after: cursor, matching: components, matchingPolicy: .nextTime)!
            }
            
            guard intervalEnd.laterDate(from) == intervalEnd else {
                cursor = calendar.nextDate(after: cursor, matching: components, matchingPolicy: .nextTime)!
                continue
            }
            
            intervalEnd = intervalEnd.earlierDate(to)
            
            interval += intervalEnd.timeIntervalSince(intervalStart)
            cursor = calendar.nextDate(after: cursor, matching: components, matchingPolicy: .nextTime)!
        }
        
        return interval
    }
    
    func estimatedCost(interval: TimeInterval, algorithm: Algorithm) -> (interval: TimeInterval, cost: Double)? {
        if self.periods.count == 0 {
            return nil
        }
        
        switch algorithm {
        case .minimum, .maximum:
            let period = algorithm == .minimum ? self.periods.keys.sorted(by: <).first! : self.periods.keys.sorted(by: >).first!
            let count = ceil(interval / TimeInterval(period))
            
            return (count * TimeInterval(period), self.periods[period]! * count)
        case .greedy:
            let periods = self.periods.keys.sorted(by: >).map(TimeInterval.init)
            
            var remaining = interval
            var cost = 0.0
            
            for period in periods {
                if period > remaining {
                    continue
                }
                
                let count = floor(remaining / period)
                cost += count * self.periods[Int(period)]!
                remaining -= count * period
            }
            
            if remaining > 0 {
                cost += self.periods[Int(periods.last!)]!
                remaining -= periods.last!
            }
            
            return (interval - remaining, cost)
        }
    }
}

extension Date {
    func laterDate(_ other: Date) -> Date {
        return self.timeIntervalSince(other) >= 0 ? self : other
    }
    
    func earlierDate(_ other: Date) -> Date {
        return self.timeIntervalSince(other) <= 0 ? self : other
    }
}

// MARK: Cereal

extension Zone.Tariff.Day: CerealType {
    init(decoder: CerealDecoder) throws {
        self.init(rawValue: try decoder.decode(key: "rawValue")!)
    }
    
    func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.rawValue, forKey: "rawValue")
    }
}

extension Zone.Tariff: CerealType {
    private struct Keys {
        static let days = "days"
        static let periods = "periods"
        static let periodStart = "periodStart"
        static let periodEnd = "periodEnd"
        static let freePeriod = "freePeriod"
        static let minPeriod = "minPeriod"
        static let minAmount = "minAmount"
    }
    
    init(decoder: CerealDecoder) throws {
        let days: Zone.Tariff.Day = try decoder.decode(key: Keys.days)!
        let periods: [Int: Double] = try decoder.decode(key: Keys.periods)!
        let periodStart: Int? = try decoder.decode(key: Keys.periodStart)
        let periodEnd: Int? = try decoder.decode(key: Keys.periodEnd)
        let freePeriod: Int? = try decoder.decode(key: Keys.freePeriod)
        let minPeriod: Int? = try decoder.decode(key: Keys.minPeriod)
        let minAmount: Double? = try decoder.decode(key: Keys.minAmount)
        
        self.init(days: days, periods: periods, periodStart: periodStart, periodEnd: periodEnd, freePeriod: freePeriod, minPeriod: minPeriod, minAmount: minAmount)
    }
    
    func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.days, forKey: Keys.days)
        try encoder.encode(self.periods, forKey: Keys.periods)
        try encoder.encode(self.periodStart, forKey: Keys.periodStart)
        try encoder.encode(self.periodEnd, forKey: Keys.periodEnd)
        try encoder.encode(self.freePeriod, forKey: Keys.freePeriod)
        try encoder.encode(self.minPeriod, forKey: Keys.minPeriod)
        try encoder.encode(self.minAmount, forKey: Keys.minAmount)
    }
}

extension Zone.Region.Location: CerealType {
    private struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
    }
    
    init(decoder: CerealDecoder) throws {
        self.init(latitude: try decoder.decode(key: Keys.latitude)!, longitude: try decoder.decode(key: Keys.longitude)!)
    }
    
    func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.latitude, forKey: Keys.latitude)
        try encoder.encode(self.longitude, forKey: Keys.longitude)
    }
}

extension Zone.Region: CerealType {
    private struct Keys {
        static let points = "points"
        static let interiorRegions = "interiorRegions"
    }

    init(decoder: CerealDecoder) throws {
        let points: [Location] = try decoder.decodeCereal(key: Keys.points)!
        let interiorRegions: [Zone.Region] = try decoder.decodeCereal(key: Keys.interiorRegions)!
        
        self.init(points: points, interiorRegions: interiorRegions)
    }
    
    func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.points, forKey: Keys.points)
        try encoder.encode(self.interiorRegions, forKey: Keys.interiorRegions)
    }
}

extension Zone: CerealType {
    private struct Keys {
        static let id = "id"
        static let code = "code"
        static let beaconMinor = "beaconMinor"
        static let tariffs = "tariffs"
        static let regions = "regions"
    }
    
    init(decoder: CerealDecoder) throws {
        let id: Int = try decoder.decode(key: Keys.id)!
        let code: String = try decoder.decode(key: Keys.code)!
        let beaconMinor: Int? = try decoder.decode(key: Keys.beaconMinor)
        let tariffs: [Zone.Tariff] = try decoder.decodeCereal(key: Keys.tariffs)!
        let regions: [Zone.Region] = try decoder.decodeCereal(key: Keys.regions)!
        
        self.init(id: id, code: code, tariffs: tariffs, regions: regions, beaconMinor: beaconMinor)
    }
    
    func encodeWithCereal(_ encoder: inout CerealEncoder) throws {
        try encoder.encode(self.id, forKey: Keys.id)
        try encoder.encode(self.code, forKey: Keys.code)
        try encoder.encode(self.beaconMinor, forKey: Keys.beaconMinor)
        try encoder.encode(self.tariffs, forKey: Keys.tariffs)
        try encoder.encode(self.regions, forKey: Keys.regions)
    }
}
