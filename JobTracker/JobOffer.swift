//
//  JobOffer.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/6/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobOffer: NSManagedObject {

    @NSManaged var dateReceived: NSDate
    @NSManaged var salary: NSNumber?
    @NSManaged var notes: String
    @NSManaged var basic: JobBasic

}
