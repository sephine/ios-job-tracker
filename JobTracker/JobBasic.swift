//
//  JobBasic.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/23/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobBasic: NSManagedObject {

    @NSManaged var company: String
    @NSManaged var title: String
    @NSManaged var stage: NSNumber
    @NSManaged var highestInterviewNumber: NSNumber?
    @NSManaged var details: JobDetail
    @NSManaged var contacts: JobContact?
    @NSManaged var location: JobLocation
    @NSManaged var application: JobApplication?
    @NSManaged var interviews: NSSet?
    @NSManaged var decision: JobDecision?
    @NSManaged var offer: JobOffer?
    @NSManaged var rejected: JobRejected?
    
    //TODO should location be optional?
}
