//
//  NSDate+Utilities.swift
//
//  Created by Jarrod Glasgow on 5/23/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

extension Date {
    
    public func differenceInDaysWithDate(date: Date) -> Int {
        let calendar: Calendar = Calendar.current

        let date1 = calendar.startOfDay(for: self as Date)
        let date2 = calendar.startOfDay(for: date as Date)

        let components = calendar.dateComponents([.day], from: date1, to: date2)

        // This only counts the "midnights" between two dates so we pad it with a day
        return components.day! + 1
    }

    public func isBetweeen(date date1: Date, andDate date2: Date) -> Bool {
        return date1.compare(self as Date).rawValue * self.compare(date2 as Date).rawValue >= 0
    }

    public func toISOString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.string(from: self as Date)
    }

    public static func fromISOString(dateString : String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        if let result = formatter.date(from: dateString) {
            return result
        }

        // Update format
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: dateString)!
    }

    public func toAmericanShortDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: self)
    }

    public func toShortDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self as Date)
    }

    public static func fromShortDateString(dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let result = formatter.date(from: dateString) {
            return result
        }

        return Date()
    }

    public func localDate() -> Date {
        let timezoneOffset = Calendar.current.timeZone.secondsFromGMT()
        return self.addingTimeInterval(TimeInterval(timezoneOffset)) as Date
    }

    public func endOfDay() -> Date {
        let testDate = self.localDate()

        // Strip off the time
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)!

        let dateWithoutTimeString = formatter.string(from: testDate as Date)
        let dateWithoutTime = formatter.date(from: dateWithoutTimeString)!

        // Add all the seconds of the day minus one
        return dateWithoutTime.addingTimeInterval(86399)
    }

    public static func lastMonday() -> Date {
        let calendar: Calendar = Calendar.current

        // Get the current components
        let now = Date()
        var nowComps = calendar.dateComponents([.day, .month, .year, .weekOfYear, .weekday], from: now)

        // Calculate Monday's comps
        var mondayComps = DateComponents()
        mondayComps.year = nowComps.year
        mondayComps.weekOfYear = nowComps.weekOfYear
        mondayComps.weekday = 2

        // Calculate Dates
        var monday = calendar.date(from: mondayComps)

        // If today is Monday then go back a week
        if (nowComps.weekday == 2) {
            monday = monday?.addingTimeInterval(24*60*60*7*(-1))
        }

        return monday!
    }
}
