//
//  JobDetail.swift
//  
//
//  Created by Joanne Dyer on 2/23/15.
//
//

import Foundation
import CoreData

class JobDetail: NSManagedObject {

    @NSManaged var dueDate: NSDate?
    @NSManaged var glassdoorLink: String
    @NSManaged var jobListing: String
    @NSManaged var notes: String
    @NSManaged var salary: NSNumber?
    @NSManaged var website: String
    @NSManaged var basic: JobBasic

}



/*@NSManaged var company: String
@NSManaged var title: String
@NSManaged var stage: NSNumber
@NSManaged var date: NSDate?
@NSManaged var details: JobDetail
@NSManaged var contacts: NSSet
@NSManaged var location: JobLocation
@NSManaged var application: JobApplication?
@NSManaged var interviews: NSSet
@NSManaged var offer: JobOffer?
@NSManaged var rejected: JobRejected?

var inFuture: Bool {
    let stageEnum = Stage(rawValue: stage.integerValue)
    if stageEnum == .Potential {
        if date == nil {
            return true
        }
        let calendar = NSCalendar.currentCalendar()
        let startOfDate = calendar.startOfDayForDate(date!)
        let startOfToday = calendar.startOfDayForDate(NSDate())
        
        let comparison = calendar.compareDate(startOfDate, toDate: startOfToday, toUnitGranularity: .CalendarUnitDay)
        return comparison == NSComparisonResult.OrderedDescending
    } else if stageEnum == .PreInterview {
        return true
    }
    return false
}

var orderedInterviews: [JobInterview] {
    let sortDescriptor = NSSortDescriptor(key: "starts", ascending: true)
    let sortedArray = interviews.sortedArrayUsingDescriptors([sortDescriptor])
    return sortedArray as [JobInterview]
}

var orderedContacts: [JobContact] {
    let sortedArray = contacts.allObjects.sorted({ (one, two) -> Bool in
        let one = one as JobContact
        let two = two as JobContact
        
        var oneSortText: String
        if !one.last.isEmpty {
            oneSortText = one.last
        } else if !one.first.isEmpty {
            oneSortText = one.first
        } else {
            oneSortText = one.company
        }
        var twoSortText: String
        if !two.last.isEmpty {
            twoSortText = two.last
        } else if !two.first.isEmpty {
            twoSortText = two.first
        } else {
            twoSortText = two.company
        }
        return oneSortText < twoSortText
    })
    return sortedArray as [JobContact]
}*/

//TODO cope with future core date model changes
