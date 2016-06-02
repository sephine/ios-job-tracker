//
//  EventManager.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/26/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import EventKitUI

protocol EventCreationDelegate: class {
    func eventCreated(event event: EKEvent, wasSaved: Bool)
}

protocol EventLoadingDelegate: class {
    func eventLoaded(wasDeleted wasDeleted: Bool)
}

class EventManager: NSObject, EKEventEditViewDelegate {
    
    let store = EKEventStore()
    weak var creationDelegate: EventCreationDelegate?
    weak var loadingDelegate: EventLoadingDelegate?
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
        if EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.NotDetermined {
            store.requestAccessToEntityType(EKEntityType.Event, completion: { (granted, error) in
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.setAccessToCalendar()
                    completion()
                })
            })
        }
    }
    
    private func setAccessToCalendar() {
        if EKEventStore.authorizationStatusForEntityType(EKEntityType.Event) == EKAuthorizationStatus.Authorized {
            accessToCalendarGranted = true
        } else {
            accessToCalendarGranted = false
        }
    }
    
    //MARK:- Create/Update/Load Calendar Events
    
    func syncInterviewWithCalendarEvent(interview interview: JobInterview) {
        if accessToCalendarGranted && !interview.eventID.isEmpty {
            let event = store.eventWithIdentifier(interview.eventID)
            if event != nil {
                updateInterviewToMatchEvent(event!, interview: interview)
            } else {
                findNewEventIDForInterview(interview)
            }
        }
        
        //the act of saving automatically ensures that the stage is correct in the case where the event could not be updated above.
        do {
            try Common.managedContext.save()
        } catch {
            print("Could not save.")
        }
    }

    func loadEventInEventEditVC(interviewToUpdate interviewToUpdate: JobInterview, viewController: UIViewController) {

        assert(!interviewToUpdate.eventID.isEmpty, "loadEventInEventEditVC should not be called with an interview that has no eventID")
        
        creatingEvent = false
        self.interviewToUpdate = interviewToUpdate
        event = store.eventWithIdentifier(interviewToUpdate.eventID)
        if event != nil {
            self.viewController = viewController
            //TODO what if it fails?
            let controller = EKEventEditViewController()
            controller.eventStore = store
            controller.editViewDelegate = self
            controller.event = event
        
            viewController.presentViewController(controller, animated: true, completion: nil)
        } else {
            findNewEventIDForInterview(interviewToUpdate)
        }
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
    
    //for when the currently stored ID no longer works.
    private func findNewEventIDForInterview(interview: JobInterview) {
        let predicate = store.predicateForEventsWithStartDate(interview.starts, endDate: interview.ends, calendars: nil)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let events = self.store.eventsMatchingPredicate(predicate)
            dispatch_async(dispatch_get_main_queue()) {
                self.fetchedPossibleIDsForInterview(interview, events: events)
            }
        }
    }
    
    func fetchedPossibleIDsForInterview(interview: JobInterview, events: [AnyObject]?) {
        var correctEventID = ""
        if events != nil {
            for event in events! {
                let event = event as! EKEvent
                if event.title == interview.title && event.startDate == interview.starts && event.endDate == interview.ends {
                    correctEventID = event.eventIdentifier
                    break
                }
            }
        }
        
        interview.eventID = correctEventID
        do {
            try Common.managedContext.save()
        } catch {
            print("Could not save.")
        }
        
        if interview.eventID.isEmpty {
            //the event cannot be found
            let alert = UIAlertView(title: "\(interview.title) Not Found", message: "The event cannot be found. It may have been moved to a different calendar or deleted. The stored interview data will no longer be updated with changes made outside this application.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else {
            let event = store.eventWithIdentifier(interview.eventID)
            if event != nil {
                updateInterviewToMatchEvent(event!, interview: interview)
            }
        }
    }
    
    private func updateInterviewToMatchEvent(event: EKEvent, interview: JobInterview) {
        interview.title = event.title
        interview.eventID = event.eventIdentifier
        interview.starts = event.startDate
        interview.ends = event.endDate
        
        //if we already have a correct lat and long, don't delete them
        if interview.location.address != event.location! {
            interview.location.address = event.location!
            interview.location.latitude = nil
            interview.location.longitude = nil
        }
        
        if event.hasNotes {
            interview.notes = event.notes!
        } else {
            interview.notes = ""
        }
        
        do {
            try Common.managedContext.save()
        } catch {
            print("Could not save.")
        }
    }

    //MARK:- EKEventEditViewDelegate
    
    func eventEditViewController(controller: EKEventEditViewController!, didCompleteWithAction action: EKEventEditViewAction) {
        viewController.dismissViewControllerAnimated(true, completion: nil)
        if creatingEvent {
            if action == EKEventEditViewAction.Saved {
                creationDelegate?.eventCreated(event: event, wasSaved: true)
            } else {
                creationDelegate?.eventCreated(event: event, wasSaved: false)
            }
        } else {
            if accessToCalendarGranted {
                if action == EKEventEditViewAction.Deleted {
                    interviewToUpdate.eventID = ""
                    do {
                        try Common.managedContext.save()
                    } catch {
                        print("Could not save.")
                    }
                    
                    loadingDelegate?.eventLoaded(wasDeleted: true)
                } else {
                    updateInterviewToMatchEvent(event, interview: interviewToUpdate)
                    loadingDelegate?.eventLoaded(wasDeleted: false)
                }
            }
        }
        //the below are stored just long enough for this method to use them.
        viewController = nil
        interviewToUpdate = nil
        event = nil
    }
}