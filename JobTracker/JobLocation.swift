//
//  JobLocation.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/20/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobLocation: NSManagedObject {

    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var address: String
    @NSManaged var basic: JobBasic

}
