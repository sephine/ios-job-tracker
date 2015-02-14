//
//  JobDetail.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/13/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobDetail: NSManagedObject {

    @NSManaged var location: String
    @NSManaged var salary: NSNumber?
    @NSManaged var website: String
    @NSManaged var jobListing: String
    @NSManaged var dueDate: NSDate?
    @NSManaged var notes: String
    @NSManaged var glassdoorLink: String
    @NSManaged var basic: JobBasic

}
