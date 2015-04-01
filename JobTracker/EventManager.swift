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
    func eventLoaded(#wasDeleted: Bool)
}

class EventManager: NSObject, EKEventEditViewDelegate {
    
    let store = EKEventStore()
    var creationDelegate: EventCreationDelegate?
    var loadingDelegate: EventLoadingDelegate?
    var accessToCalendarGranted = false
    
    private var event: EKEvent!
    private var interviewToUpdate: JobInterview!
    private var viewController: UIViewController!
    private var creatingEvent = false
    
    //MARK:- Singleton Class Creation
    
    class var sharedInstance: EventManager {
        struct Static {
            static let instance = EventManager()
        }
        return Static.instance
    }
    
    private override init() {
        super.init()
        setAccessToCalendar()
    }
    
    //MARK:- Calendar Access
    
    func askForCalendarAccessWithCompletion(completion: () -> Void) {
        if EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) == EKAuthorizationStatus.NotDetermined {
            store.requestAccessToEntityType(EKEntityTypeEvent, completion: { (granted, error) in
                self.setAccessToCalendar()
                completion()
            })
        }
    }
    
    private func setAccessToCalendar() {
        if EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent) == EKAuthorizationStatus.Authorized {
            accessToCalendarGranted = true
        } else {
            accessToCalendarGranted = false
        }
    }
    
    //MARK:- Create/Update/Load Calendar Events
    
    func syncInterviewWithCalendarEvent(#interview: JobInterview) {
        if accessToCalendarGranted && !interview.eventID.isEmpty {
            let event = store.eventWithIdentifier(interview.eventID)
            updateInterviewToMatchEvent(event, interview: interview)
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
    
    //MARK:-
    
    private func updateInterviewToMatchEvent(event: EKEvent, interview: JobInterview) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        interview.title = event.title
        interview.location.address = event.location
        interview.location.latitude = nil
        interview.location.longitude = nil
        interview.starts = event.startDate
        interview.ends = event.endDate
        if event.hasNotes {
            interview.notes = event.notes
        } else {
            interview.notes = ""
        }
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }

    
    //MARK:- EKEventEditViewDelegate
    
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
        if creatingEvent {
            if action.value == EKEventEditViewActionSaved.value {
                creationDelegate?.eventCreated(event: event, wasSaved: true)
            } else {
                creationDelegate?.eventCreated(event: event, wasSaved: false)
            }
        } else {
            if accessToCalendarGranted {
                updateInterviewToMatchEvent(event, interview: interviewToUpdate)
                if action.value == EKEventEditViewActionDeleted.value {
                    interviewToUpdate.eventID = ""
                    loadingDelegate?.eventLoaded(wasDeleted: true)
                } else {
                    loadingDelegate?.eventLoaded(wasDeleted: false)
                }
            }
        }
    }
}