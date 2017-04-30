//
//  ModelExtensions.swift
//  Pargi
//
//  Created by Henri Normak on 30/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation

extension Zone {
    ///
    /// - returns: Combined textual description of the tariffs on the zone
    ///
    func localizedTariffDescription() -> String {
        guard self.tariffs.count > 0 else {
            return "UI.NoPriceInfo".localized(withComment: "No price info found")
        }
        
        return self.tariffs.map({ $0.localizedDescription() }).joined(separator: "\n")
    }
}

fileprivate let CalendarFirstDay = NSCalendar.autoupdatingCurrent.firstWeekday
fileprivate let CalendarShortDays = DateFormatter().shortStandaloneWeekdaySymbols.shift(withDistance: (CalendarFirstDay - 1))
fileprivate let Formatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.zeroFormattingBehavior = .pad
    
    return formatter
}()

fileprivate let AlternateFormatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute]
    formatter.zeroFormattingBehavior = [.pad, .dropTrailing, .dropLeading]
    formatter.unitsStyle = .short
    
    return formatter
}()

fileprivate let CurrencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = "EUR"
    
    return formatter
}()

fileprivate extension Zone.Tariff {
    func localizedDescription() -> String {
        // Days
        var parts = [String]()
        parts.append(self.days.localizedDescription())
        
        // Duration (start - end during day)
        if let start = self.periodStart, let end = self.periodEnd {
            parts.append("\(Formatter.string(from: Double(start))!) - \(Formatter.string(from: Double(end))!)")
        } else if let start = self.periodStart {
            parts.append("\(Formatter.string(from: Double(start))!) - \(Formatter.string(from: Double(86400))!)")
        } else if let end = self.periodEnd {
            parts.append("\(Formatter.string(from: Double(0))!) - \(Formatter.string(from: Double(end))!)")
        } else {
            parts.append(AlternateFormatter.string(from: Double(86400))!)
        }
        
        // Append the smallest unit of cost
        if let unit = self.periods.keys.sorted(by: <).first {
            let amount = NSNumber(value: Double(self.periods[unit]!) / 100)
            parts.append("\(AlternateFormatter.string(from: Double(unit))!) \(CurrencyFormatter.string(from: amount)!)")
        }
        
        return parts.joined(separator: ", ")
    }
}

fileprivate extension Zone.Tariff.Day {
    func localizedDescription() -> String {
        if self.contains(.All) {
            // All days
            return "\(CalendarShortDays[0]) - \(CalendarShortDays[CalendarShortDays.endIndex - 1])"
        } else if self.contains(.Weekdays) {
            // All weekdays
            return "\(CalendarShortDays[0]) - \(CalendarShortDays[4])"
        } else if self.contains(.Weekend) {
            // All weekends
            return "\(CalendarShortDays[5]) - \(CalendarShortDays[6])"
        }
        
        var result: [String] = []
        
        if self.contains(.Monday) {
            result.append(CalendarShortDays[0])
        }
        
        if self.contains(.Tuesday) {
            result.append(CalendarShortDays[1])
        }
        
        if self.contains(.Wednesday) {
            result.append(CalendarShortDays[2])
        }
        
        if self.contains(.Thursday) {
            result.append(CalendarShortDays[3])
        }
        
        if self.contains(.Friday) {
            result.append(CalendarShortDays[4])
        }
        
        if self.contains(.Saturday) {
            result.append(CalendarShortDays[5])
        }
        
        if self.contains(.Sunday) {
            result.append(CalendarShortDays[6])
        }
        
        return result.joined(separator: ", ")
    }
}
