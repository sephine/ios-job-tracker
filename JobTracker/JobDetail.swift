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
    @NSManaged var appliedStarted: Bool
    @NSManaged var interviewStarted: Bool
    @NSManaged var decisionStarted: Bool
    @NSManaged var offerStarted: Bool
    @NSManaged var basic: JobBasic

}
