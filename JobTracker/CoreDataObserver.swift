//
//  CoreDataObserver.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/20/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import CoreData

class CoreDataObserver: NSObject {
    
    //MARK:- Singleton Class Creation
    
    class var sharedInstance: CoreDataObserver {
        struct Static {
            static let instance = CoreDataObserver()
        }
        return Static.instance
    }
    
    //singleton class, use sharedInstance to get an instance of the class.
    override private init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "notificationReceived:", name: NSManagedObjectContextWillSaveNotification, object: Common.managedContext)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //MARK:- Managing Changes In Core Data
    
    func notificationReceived(notification: NSNotification) {
        //if anything but a JobLocation is altered we will get the JobBasic from it and make sure that it has the correct stage and date.
        let context = notification.object! as NSManagedObjectContext
        let allModifiedObjects = context.insertedObjects.setByAddingObjectsFromSet(context.deletedObjects).setByAddingObjectsFromSet(context.updatedObjects)
        for object in allModifiedObjects.allObjects {
            if object is JobBasic {
                updateStageAndDateForJobBasic(object as JobBasic)
                break
            } else if !(object is JobLocation) {
                let jobBasic = object.valueForKey("basic") as JobBasic?
                if jobBasic != nil {
                    updateStageAndDateForJobBasic(jobBasic!)
                    break
                }
            }
        }
    }

    func updateStageAndDateForJobBasic(jobBasic: JobBasic) {
        var newStage: Stage
        if jobBasic.rejected != nil {
            newStage = Stage.Rejected
        } else if jobBasic.offer != nil {
            newStage = Stage.Offer
        } else if jobBasic.interviews.count != 0 {
            var allComplete = true
            for interview in jobBasic.orderedInterviews {
                if !interview.completed {
                    allComplete = false
                    break
                }
            }
            
            if allComplete {
                newStage = Stage.PostInterview
            } else {
                newStage = Stage.PreInterview
            }
        } else if jobBasic.application != nil {
            newStage = Stage.Applied
        } else {
            newStage = Stage.Potential
        }
        
        if newStage.rawValue != jobBasic.stage {
            jobBasic.stage = newStage.rawValue
        }
        
        updateDateForJobBasic(jobBasic)
    }
    
    func updateDateForJobBasic(jobBasic: JobBasic) {
        let stage = Stage(rawValue: jobBasic.stage.integerValue)!
        var newDate: NSDate!
        switch stage {
        case .Potential:
            //set the date stored for dueDate as the end of the day, as we want it to show up as not passed until the whole day is passed. If there is no due date set it as far in the future.
            let calendar = NSCalendar.currentCalendar()
            if let dueDate = jobBasic.details.dueDate {
                newDate = calendar.dateBySettingHour(23, minute: 59, second: 59, ofDate: dueDate, options: nil)!
            } else {
                newDate = NSDate.distantFuture() as NSDate
            }
        case .Applied:
            newDate = jobBasic.application!.dateSent
        case .PreInterview:
            for interview in jobBasic.orderedInterviews {
                if !interview.completed {
                    newDate = interview.starts
                    break
                }
            }
        case .PostInterview:
            newDate = jobBasic.orderedInterviews.last!.ends
        case .Offer:
            newDate = jobBasic.offer!.dateReceived
        case .Rejected:
            newDate = jobBasic.rejected!.dateRejected
        }
        
        if newDate != jobBasic.date {
            jobBasic.date = newDate
        }
    }
}