//
//  JobBasic.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/6/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class JobBasic: NSManagedObject {

    @NSManaged var company: String
    @NSManaged var title: String
    @NSManaged var stage: NSNumber
    @NSManaged var details: JobDetail

}