//
//  EventManager.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/26/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import EventKitUI

protocol EventCreationDelegate {
    func eventCreated(#event: EKEvent, wasSaved: Bool)
}

protocol EventLoadingDelegate {
    func eventLoaded()
}

class EventManager: NSObject, EKEventEditViewDelegate {
    
    let store = EKEventStore()
    var creationDelegate: EventCreationDelegate!
    var loadingDelegate: EventLoadingDelegate!
    var accessToCalendarGranted = false
    
    private var event: EKEvent!
    private var interviewToUpdate: JobInterview!
    private var viewController: UIViewController!
    private var creatingEvent = false
    
    class var sharedInstance: EventManager {
        struct Static {
            static let instance = EventManager()
        }
        return Static.instance
    }
    
    override private init() {
        //use singleton instance
    }
    
    func updateCalendarAccess() {
        store.requestAccessToEntityType(EKEntityTypeEvent, completion: { (granted: Bool, error: NSError?) in
            if granted {
                self.accessToCalendarGranted = true
            } else {
                self.accessToCalendarGranted = false
            }
        })
    }
    
    func syncInterviewWithCalendarEvent(#interview: JobInterview) {
        let event = store.eventWithIdentifier(interview.eventID)
        updateInterviewToMatchEvent(event, interview: interview)
    }
    
    private func updateInterviewToMatchEvent(event: EKEvent, interview: JobInterview) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        interview.title = event.title
        interview.location.address = event.location
        interview.location.latitude = nil
        interview.location.longitude = nil
        interview.starts = event.startDate
        interview.ends = event.endDate
        interview.notes = event.notes
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    func loadEventInEventEditVC(#interviewToUpdate: JobInterview, viewController: UIViewController) {
        creatingEvent = false
        self.interviewToUpdate = interviewToUpdate
        event = store.eventWithIdentifier(interviewToUpdate.eventID)
        self.viewController = viewController
        //TODO what if it fails?
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.editViewDelegate = self
        controller.event = event
        
        viewController.presentViewController(controller, animated: true, completion: nil)
    }
    
    func createEventInEventEditVC(event: EKEvent, viewController: UIViewController) {
        creatingEvent = true
        self.event = event
        self.viewController = viewController
        
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.editViewDelegate = self
        controller.event = event
        
        viewController.presentViewController(controller, animated: true, completion: nil)
    }
    
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
        if creatingEvent {
            if action.value == EKEventEditViewActionSaved.value {
                creationDelegate.eventCreated(event: event, wasSaved: true)
            } else {
                creationDelegate.eventCreated(event: event, wasSaved: false)
            }
        } else {
            updateInterviewToMatchEvent(event, interview: interviewToUpdate)
            if action.value == EKEventEditViewActionDeleted.value {
                interviewToUpdate.eventID = ""
            }
            loadingDelegate.eventLoaded()
        }
        
    }
}