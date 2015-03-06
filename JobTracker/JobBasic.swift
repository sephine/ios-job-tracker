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
    @NSManaged var details: JobDetail
    @NSManaged var contacts: JobContact?
    @NSManaged var location: JobLocation
    @NSManaged var application: JobApplication?
    @NSManaged var interviews: NSSet
    @NSManaged var offer: JobOffer?
    @NSManaged var rejected: JobRejected?
    
    var orderedInterviews: [JobInterview] {
        let sortDescriptor = NSSortDescriptor(key: "ends", ascending: true)
        let sortedArray = interviews.sortedArrayUsingDescriptors([sortDescriptor])
        return sortedArray as [JobInterview]
    }
    
    //used to get the correct current stage after deletion for example. Will still need to be saved.
    func updateStageToFurthestStageReached() {
        if rejected != nil {
            stage = Stage.Rejected.rawValue
        } else if offer != nil {
            stage = Stage.Offer.rawValue
        } else if interviews.count != 0 {
            var allComplete = true
            for interview in interviews {
                if !(interview as JobInterview).completed {
                    allComplete = false
                    break
                }
            }
            if allComplete {
                stage = Stage.PostInterview.rawValue
            } else {
                stage = Stage.PreInterview.rawValue
            }
        } else if application != nil {
            stage = Stage.Applied.rawValue
        } else {
            stage = Stage.Potential.rawValue
        }
    }
}
