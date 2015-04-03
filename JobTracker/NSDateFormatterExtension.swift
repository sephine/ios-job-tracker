//
//  NSDateFormatterExtension.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/31/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

extension NSDateFormatter {
    
    func stringFromDifferenceInDateToToday(#date: NSDate) -> String {
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        
        //use the start of the dates so that the time of day does not affect the number of days difference.
        let startOfDate = calendar.startOfDayForDate(date)
        let startOfToday = calendar.startOfDayForDate(today)
        
        let components = calendar.components(.YearCalendarUnit | .MonthCalendarUnit | .DayCalendarUnit, fromDate: startOfToday, toDate: startOfDate, options: nil)
        let year = components.year
        let month = components.month
        let day = components.day
        
        var inPast = false
        var appendS = false
        var dateString: String
        if year != 0 {
            inPast = year < 0
            appendS = abs(year) > 1
            dateString = "\(abs(year)) year"
        } else if month != 0 {
            inPast = month < 0
            appendS = abs(month) > 1
            dateString = "\(abs(month)) month"
        } else if abs(day) >= 7 {
            let week: Int = day/7
            inPast = week < 0
            appendS = abs(week) > 1
            dateString = "\(abs(week)) week"
        } else if day == 0 {
            return "today"
        } else if day == 1 {
            return "tomorrow"
        } else if day == -1 {
            return "yesterday"
        } else {
            inPast = day < 0
            appendS = abs(day) > 1
            dateString = "\(abs(day)) day"
        }
        
        if appendS {
            dateString = "\(dateString)s"
        }
        
        if inPast {
            dateString = "\(dateString) ago"
        } else {
            dateString = "in \(dateString)"
        }
        return dateString
    }
}