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

    @NSManaged var name: String
    @NSManaged var basic: JobBasic

}
