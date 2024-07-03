//
//  Date.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation


extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date {
    func toString() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: self)
    }
    
    var tomorrow: Date {
        daysFromNow(1)
    }
    
    var yesterday: Date {
        daysFromNow(-1)
    }
    
    func daysFromNow(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self)!
    }
    
    func monthsFromNow(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self)!
    }

    var utcString: String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: self)
    }
    
    var endOfDay: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDay = calendar.startOfDay(for: self)
        let endOfDay = calendar.date(byAdding: .second, value: 86399, to: startOfDay)
        return endOfDay!
    }
    
    var startOfDay: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDay = calendar.startOfDay(for: self)
        return startOfDay
    }
    
    static func getUTCStartEndTime(from timestamp: TimeInterval) -> (startTime: Date, endTime: Date)? {
        let date = Date(timeIntervalSince1970: timestamp)
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startOfDay = calendar.startOfDay(for: date)
        
        guard let endOfDay = calendar.date(byAdding: .second, value: 86399, to: startOfDay) else {
            return nil
        }
        
        return (startTime: startOfDay, endTime: endOfDay)
    }
    
    var startOfMonth: Date {
        let dates = Self.getUTCStartEndTime(from: self.timeIntervalSince1970)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let components = calendar.dateComponents([.year, .month], from: dates?.startTime ?? self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        var components = DateComponents()
        components.month = 1
        components.second = -1
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(byAdding: components, to: startOfMonth) ?? self
    }
}
