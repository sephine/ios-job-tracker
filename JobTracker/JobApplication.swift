//
//  JobApplication.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/22/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobApplication: NSManagedObject {

    @NSManaged var dateSent: NSDate?
    @NSManaged var notes: String
    @NSManaged var basic: JobBasic

}
