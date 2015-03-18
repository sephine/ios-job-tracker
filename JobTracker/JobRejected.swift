//
//  JobRejected.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/6/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobRejected: NSManagedObject {

    @NSManaged var notes: String
    @NSManaged var dateRejected: NSDate
    @NSManaged var basic: JobBasic

}
