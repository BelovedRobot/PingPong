//
//  NSDate+Utilities.swift
//  Deshazo
//
//  Created by Jarrod Glasgow on 5/23/16.
//  Copyright © 2016 Beloved Robot. All rights reserved.
//

import Foundation

extension NSDate {
    
    func differenceInDaysWithDate(date: NSDate) -> Int {
        let calendar: NSCalendar = NSCalendar.currentCalendar()
        
        let date1 = calendar.startOfDayForDate(self)
        let date2 = calendar.startOfDayForDate(date)
        
        let components = calendar.components(.Day, fromDate: date1, toDate: date2, options: [])
        // This only counts the "midnights" between two dates so we pad it with a day
        return components.day + 1
    }
    
    func isBetweeen(date date1: NSDate, andDate date2: NSDate) -> Bool {
        return date1.compare(self).rawValue * self.compare(date2).rawValue >= 0
    }
    
    func toISOString() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.stringFromDate(self)
    }
    
    static func fromISOString(dateString : String) -> NSDate {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.dateFromString(dateString)!
    }
    
    func toShortDateString() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.stringFromDate(self)
    }
    
    func localDate() -> NSDate {
        let timezoneOffset = Double(NSCalendar.currentCalendar().timeZone.secondsFromGMT);
        return self.dateByAddingTimeInterval(timezoneOffset)
    }
    
    func endOfDay() -> NSDate {
        let testDate = self.localDate().dateByAddingTimeInterval(86399)
        
        // Strip off the time
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
        
        let dateWithoutTimeString = formatter.stringFromDate(testDate)
        let dateWithoutTime = formatter.dateFromString(dateWithoutTimeString)!
        
        // Add all the seconds of the day minus one
        return dateWithoutTime.dateByAddingTimeInterval(86399)
    }
    
    static func lastMonday() -> NSDate {
        let now = NSDate()
        var startDate: NSDate? = nil
        var duration: NSTimeInterval = 0
        
        NSCalendar.currentCalendar().rangeOfUnit(.WeekOfYear, startDate: &startDate, interval: &duration, forDate: now)
        
        // By default the start date is set to Monday
        return startDate!.dateByAddingTimeInterval(60 * 60 * 24)
    }
}