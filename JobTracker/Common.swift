//
//  Common.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/25/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class Common {
    
    class func positionStringFromNumber(number: Int) -> String? {
        let positions = [1: "First", 2: "Second", 3: "Third", 4: "Fourth", 5: "Fifth", 6: "Sixth", 7: "Seventh", 8: "Eighth", 9: "Ninth", 10: "Tenth"]
        return positions[number]
    }
    
    class func standardCurrencyFormatter() -> NSNumberFormatter {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        return formatter
    }
    
    class func standardDateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        return dateFormatter
    }
    
    class func standardDateAndTimeFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return dateFormatter
    }
}

enum Stage: Int {
    case Potential = 0, Applied, Interview, Decision, Offer, Rejected
    
    static let allValues = [Potential, Applied, Interview, Decision, Offer, Rejected]
    
    var title: String {
        switch self {
        case .Potential:
            return "Potential Job"
        case .Applied:
            return "Application Sent"
        case .Interview:
            return "Interview Arranged"
        case .Decision:
            return "Awaiting Decision"
        case .Offer:
            return "Offer Received"
        case .Rejected:
            return "Rejected"
        }
    }
}

