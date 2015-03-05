//
//  EditInterviewViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/24/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import EventKitUI

class EditInterviewViewController: UITableViewController, UITextFieldDelegate, LocationSelectionDelegate, EventCreationDelegate {

    @IBOutlet weak var addEventCell: ShowResultCell!
    @IBOutlet weak var titleBox: UITextField!
    @IBOutlet weak var locationBox: UITextField!
    @IBOutlet weak var startsBox: UITextField!
    @IBOutlet weak var endsBox: UITextField!
    @IBOutlet weak var calendarBox: UITextField!
    @IBOutlet weak var notesView: UITextView!

    var loadedBasic: JobBasic!
    var loadedInterview: JobInterview?
    
    var locationLatitude: NSNumber?
    var locationLongitude: NSNumber?
    
    let startDatePickerView = UIDatePicker()
    let endDatePickerView = UIDatePicker()
    let dateFormatter = NSDateFormatter()
    var locationJustCleared = false
    var timeInterval: NSTimeInterval!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !EventManager.sharedInstance.accessToCalendarGranted {
            addEventCell.userInteractionEnabled = false
            addEventCell.mainLabel.enabled = false
        }
        
        setUpDatePickers()
        
        if loadedInterview == nil {
            if loadedBasic.highestInterviewNumber == 0 {
                title = "Add Interview"
            } else {
                let newInterviewNumber = loadedBasic.highestInterviewNumber.integerValue + 1
                title = "Add Interview \(newInterviewNumber)"
            }
            
            setControlValuesToDefaults()
        } else {
            if loadedBasic.highestInterviewNumber.integerValue == 1 {
                title = "Edit Interview"
            } else {
                title = "Edit Interview \(loadedInterview!.interviewNumber)"
            }
            
            setControlValuesToLocallySavedData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //show toolbar only on edit interview (not create new)
        if loadedInterview != nil {
            self.navigationController?.toolbarHidden = false
        } else {
            self.navigationController?.toolbarHidden = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.toolbarHidden = true
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        locationJustCleared = true
        locationLatitude = nil
        locationLongitude = nil
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if locationJustCleared {
            locationJustCleared = false
        } else {
            performSegueWithIdentifier("findLocation", sender: self)
        }
        return false
    }

    func locationSelected(address: String) {
        locationBox.text = address
    }
    
    func coordinatesCalculated(coordinates: CLLocationCoordinate2D) {
        if !locationBox.text.isEmpty {
            locationLatitude = coordinates.latitude
            locationLongitude = coordinates.longitude
        }
    }
    
    func setControlValuesToDefaults() {
        //get today's date and the last complete hour.
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour, fromDate: today)
        let initialStarts = calendar.dateFromComponents(dateComponents)!
        dateComponents.hour += 1
        let initialEnds = calendar.dateFromComponents(dateComponents)!
        
        startsBox.text = dateFormatter.stringFromDate(initialStarts)
        startDatePickerView.date = initialStarts
        endsBox.text = dateFormatter.stringFromDate(initialEnds)
        endDatePickerView.date = initialEnds
        timeInterval = endDatePickerView.date.timeIntervalSinceDate(startDatePickerView.date)
        
        titleBox.text = loadedBasic.company + " Interview"
        locationBox.text = loadedBasic.location.address
        locationLatitude = loadedBasic.location.latitude
        locationLongitude = loadedBasic.location.longitude
    }
    
    func setControlValuesToLocallySavedData() {
        titleBox.text = loadedInterview!.title
        locationBox.text = loadedInterview!.location.address
        locationLatitude = loadedInterview!.location.latitude
        locationLongitude = loadedInterview!.location.longitude
        
        let starts = loadedInterview!.starts as NSDate?
        if starts == nil {
            startsBox.text = ""
        } else {
            startsBox.text = dateFormatter.stringFromDate(starts!)
            startDatePickerView.date = starts!
        }
        
        let ends = loadedInterview!.ends as NSDate?
        if ends == nil {
            endsBox.text = ""
        } else {
            endsBox.text = dateFormatter.stringFromDate(ends!)
            endDatePickerView.date = ends!
        }
        
        timeInterval = endDatePickerView.date.timeIntervalSinceDate(startDatePickerView.date)
        
        //TODO calendarBox, as there is no eventID this will be something like None
        
        notesView.text = loadedInterview!.notes
    }
    
    func setUpDatePickers() {
        startDatePickerView.datePickerMode = UIDatePickerMode.DateAndTime
        startDatePickerView.addTarget(self, action: "updateStartDate", forControlEvents: UIControlEvents.ValueChanged)
        startDatePickerView.minuteInterval = 5
        startsBox.inputView = startDatePickerView
        
        endDatePickerView.datePickerMode = UIDatePickerMode.DateAndTime
        endDatePickerView.addTarget(self, action: "updateEndDate", forControlEvents: UIControlEvents.ValueChanged)
        endDatePickerView.minuteInterval = 5
        endsBox.inputView = endDatePickerView
        
        dateFormatter.dateStyle = NSDateFormatterStyle.MediumStyle
        dateFormatter.timeStyle = NSDateFormatterStyle.ShortStyle
    }

    func updateStartDate() {
        let date = startDatePickerView.date
        startsBox.text = dateFormatter.stringFromDate(date)
        
        let newEndDate = date.dateByAddingTimeInterval(timeInterval)
        endDatePickerView.date = newEndDate
        updateEndDate()
    }
    
    func updateEndDate() {
        let date = endDatePickerView.date
        endsBox.text = dateFormatter.stringFromDate(date)
        
        //work out difference between start and end date.
        timeInterval = endDatePickerView.date.timeIntervalSinceDate(startDatePickerView.date)
        
        //TODO why is box becoming center aligned?
        //TODO updating end date when start date updated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            createCalendarEvent()
        }
    }
    
    func createCalendarEvent() {
        let store = EventManager.sharedInstance.store
        let event = EKEvent(eventStore: store)
        event.calendar = store.defaultCalendarForNewEvents
        event.title = titleBox.text
        event.location = locationBox.text!
        event.startDate = Common.standardDateAndTimeFormatter().dateFromString(startsBox.text)!
        event.endDate = Common.standardDateAndTimeFormatter().dateFromString(endsBox.text)!
        event.notes = notesView.text
        let i = event.notes
        
        EventManager.sharedInstance.creationDelegate = self
        EventManager.sharedInstance.createEventInEventEditVC(event, viewController: self)
    }
    
    func eventCreated(#event: EKEvent, wasSaved: Bool) {
        if wasSaved {
            saveDetailsFollowingCreationOfEvent(event)
        }
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        saveDetailsFromControlData()
    }
    
    @IBAction func deleteClicked(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        let deleteAction = UIAlertAction(title: "Delete Interview", style: .Destructive, handler: { (action) in self.deleteInterview()
        })
        alertController.addAction(deleteAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func saveDetailsFollowingCreationOfEvent(event: EKEvent) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let interview = createOrLoadInterview()
        
        interview.eventID = event.eventIdentifier
        interview.title = event.title
        interview.starts = event.startDate
        interview.ends = event.endDate
        interview.notes = event.notes
        
        interview.location.address = event.location
        interview.location.latitude = nil
        interview.location.longitude = nil
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
        
        navigationController?.popViewControllerAnimated(true)
    }
    
    func saveDetailsFromControlData() {
        let managedContext = Common.managedContext
        let interview = createOrLoadInterview()
        
        interview.eventID = ""
        interview.title = titleBox.text
        interview.starts = dateFormatter.dateFromString(startsBox.text)!
        interview.ends = dateFormatter.dateFromString(endsBox.text)!
        interview.notes = notesView.text
        
        interview.location.address = locationBox.text!
        interview.location.latitude = locationLatitude
        interview.location.longitude = locationLongitude
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
        
        navigationController?.popViewControllerAnimated(true)
    }
    
    func createOrLoadInterview() -> JobInterview {
        var interview: JobInterview
        if loadedInterview != nil {
            interview = loadedInterview!
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            interview = NSEntityDescription.insertNewObjectForEntityForName("JobInterview", inManagedObjectContext: managedContext) as JobInterview
            let interviewLocation = NSEntityDescription.insertNewObjectForEntityForName("JobLocation", inManagedObjectContext: managedContext) as JobLocation
            managedContext.insertObject(interview)
            managedContext.insertObject(interviewLocation)
            
            let newInterviewNumber = loadedBasic.highestInterviewNumber.integerValue + 1
            loadedBasic.highestInterviewNumber = newInterviewNumber
            interview.interviewNumber = newInterviewNumber
            
            loadedBasic.interviews.setByAddingObject(interview)
            interview.basic = loadedBasic
            interview.location = interviewLocation
            loadedBasic.details.interviewStarted = true
            loadedBasic.stage = Stage.Interview.rawValue
        }
        return interview
    }
    
    func deleteInterview() {
        if loadedInterview != nil {
            let numberOfInterviews = loadedBasic.interviews.count
            if numberOfInterviews >= 2 {
                let interviewSet = loadedBasic.interviews.mutableCopy() as NSMutableSet
                var itemToRemove: JobInterview!
                for interview in interviewSet {
                    let interview = interview as JobInterview
                    if interview.interviewNumber == numberOfInterviews {
                        itemToRemove = interview
                        break
                    }
                }
                interviewSet.removeObject(itemToRemove)
                loadedBasic.interviews = interviewSet
                loadedBasic.highestInterviewNumber = numberOfInterviews - 1
            } else {
                loadedBasic.interviews = NSSet()
                loadedBasic.highestInterviewNumber = 0
                loadedBasic.details.interviewStarted = false
                if loadedBasic.stage == Stage.Interview.rawValue {
                    if loadedBasic.application != nil {
                        loadedBasic.stage = Stage.Applied.rawValue
                    } else {
                        loadedBasic.stage = Stage.Potential.rawValue
                    }
                }
            }
            
            var error: NSError?
            if !Common.managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "findLocation" {
            let destination = segue.destinationViewController as LocationTableViewController
            destination.delegate = self
        } else if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
    
    //TODO consider saving data formatters seperately
}