//
//  JobContact.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/13/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobContact: NSManagedObject {

    @NSManaged var first: String
    @NSManaged var last: String
    @NSManaged var company: String
    @NSManaged var contactID: NSNumber
    @NSManaged var basic: JobBasic
    
    //TODO change
}
