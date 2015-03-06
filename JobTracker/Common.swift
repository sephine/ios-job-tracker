//
//  Common.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/25/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

struct Common {
    
    static var managedContext: NSManagedObjectContext = (UIApplication.sharedApplication().delegate as AppDelegate).managedObjectContext!
    
    static func standardCurrencyFormatter() -> NSNumberFormatter {
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        return formatter
    }
    
    static func standardDateFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        return dateFormatter
    }
    
    static func standardDateAndTimeFormatter() -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return dateFormatter
    }
}

enum Stage: Int {
    case Potential = 0, Applied, PreInterview, PostInterview, Offer, Rejected
    
    static let allValues = [Potential, Applied, PreInterview, PostInterview, Offer, Rejected]
    
    var title: String {
        switch self {
        case .Potential:
            return "Potential Job"
        case .Applied:
            return "Application Sent"
        case .PreInterview:
            return "Interview Scheduled"
        case .PostInterview:
            return "Interview Completed"
        case .Offer:
            return "Offer Received"
        case .Rejected:
            return "Rejected"
        }
    }
}

