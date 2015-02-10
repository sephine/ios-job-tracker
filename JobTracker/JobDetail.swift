//
//  JobDetail.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/6/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobDetail: NSManagedObject {

    @NSManaged var salary: NSNumber
    @NSManaged var location: String
    @NSManaged var basic: JobBasic

}
