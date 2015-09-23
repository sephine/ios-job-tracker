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
    
    private var locationLatitude: NSNumber?
    private var locationLongitude: NSNumber?
    private var locationJustCleared = false
    
    private let startDatePickerView = UIDatePicker()
    private let endDatePickerView = UIDatePicker()
    private var timeInterval: NSTimeInterval!
    
    //MARK:- UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //ask for access to calendar if it hasn't already been done
        EventManager.sharedInstance.askForCalendarAccessWithCompletion(accessRequestCompleted)
        
        if !EventManager.sharedInstance.accessToCalendarGranted {
            addEventCell.userInteractionEnabled = false
            addEventCell.mainLabel.enabled = false
        }
        
        setUpDatePickers()
        
        if loadedInterview == nil {
            title = "Add Interview"
            setControlValuesToDefaults()
        } else {
            title = "Edit Interview"
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "findLocation" {
            let destination = segue.destinationViewController as! LocationTableViewController
            destination.delegate = self
        } else if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as! ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
    
    //MARK:-
    
    func accessRequestCompleted() {
        if EventManager.sharedInstance.accessToCalendarGranted {
            addEventCell.userInteractionEnabled = true
            addEventCell.mainLabel.enabled = true
            tableView.reloadData()
        }
    }
    
    private func setControlValuesToDefaults() {
        //get today's date and the last complete hour.
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components(.CalendarUnitYear | .CalendarUnitMonth | .CalendarUnitDay | .CalendarUnitHour, fromDate: today)
        let initialStarts = calendar.dateFromComponents(dateComponents)!
        dateComponents.hour += 1
        let initialEnds = calendar.dateFromComponents(dateComponents)!
        
        startsBox.text = Common.standardDateAndTimeFormatter.stringFromDate(initialStarts)
        startDatePickerView.date = initialStarts
        endsBox.text = Common.standardDateAndTimeFormatter.stringFromDate(initialEnds)
        endDatePickerView.date = initialEnds
        timeInterval = endDatePickerView.date.timeIntervalSinceDate(startDatePickerView.date)
        
        titleBox.text = loadedBasic.company + " Interview"
        locationBox.text = loadedBasic.location.address
        locationLatitude = loadedBasic.location.latitude
        locationLongitude = loadedBasic.location.longitude
    }
    
    private func setControlValuesToLocallySavedData() {
        titleBox.text = loadedInterview!.title
        locationBox.text = loadedInterview!.location.address
        locationLatitude = loadedInterview!.location.latitude
        locationLongitude = loadedInterview!.location.longitude
        
        let starts = loadedInterview!.starts as NSDate?
        startsBox.text = Common.standardDateAndTimeFormatter.stringFromDate(starts!)
        startDatePickerView.date = starts!
        
        let ends = loadedInterview!.ends as NSDate?
        endsBox.text = Common.standardDateAndTimeFormatter.stringFromDate(ends!)
        endDatePickerView.date = ends!
        
        timeInterval = endDatePickerView.date.timeIntervalSinceDate(startDatePickerView.date)
        
        notesView.text = loadedInterview!.notes
    }
    
    private func setUpDatePickers() {
        startDatePickerView.datePickerMode = UIDatePickerMode.DateAndTime
        startDatePickerView.addTarget(self, action: "updateStartDate", forControlEvents: UIControlEvents.ValueChanged)
        startDatePickerView.minuteInterval = 5
        startsBox.inputView = startDatePickerView
        
        endDatePickerView.datePickerMode = UIDatePickerMode.DateAndTime
        endDatePickerView.addTarget(self, action: "updateEndDate", forControlEvents: UIControlEvents.ValueChanged)
        endDatePickerView.minuteInterval = 5
        endsBox.inputView = endDatePickerView
    }
    
    func updateStartDate() {
        let date = startDatePickerView.date
        startsBox.text = Common.standardDateAndTimeFormatter.stringFromDate(date)
        
        let newEndDate = date.dateByAddingTimeInterval(timeInterval)
        endDatePickerView.date = newEndDate
        updateEndDate()
    }
    
    func updateEndDate() {
        let date = endDatePickerView.date
        endsBox.text = Common.standardDateAndTimeFormatter.stringFromDate(date)
        
        //work out difference between start and end date.
        timeInterval = endDatePickerView.date.timeIntervalSinceDate(startDatePickerView.date)
        
        //TODO: why is box becoming center aligned?
    }
    
    //MARK:- UITableViewDataSource
    
    override func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let accessGranted = EventManager.sharedInstance.accessToCalendarGranted
        if section == 0 && !accessGranted {
            return "Requires access to your calendar"
        }
        return nil
    }
    
    //MARK:- UITableViewDelegate
    
    //sets it up so that wherever in the cell they select the textbox starts editing.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            createCalendarEvent()
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                titleBox.becomeFirstResponder()
            case 2:
                startsBox.becomeFirstResponder()
            case 3:
                endsBox.becomeFirstResponder()
            case 4:
                notesView.becomeFirstResponder()
            default:
                break
            }
        }
    }
    
    //MARK:- 
    
    private func createCalendarEvent() {
        let store = EventManager.sharedInstance.store
        let event = EKEvent(eventStore: store)
        event.calendar = store.defaultCalendarForNewEvents
        event.title = titleBox.text
        event.location = locationBox.text!
        event.startDate = Common.standardDateAndTimeFormatter.dateFromString(startsBox.text)!
        event.endDate = Common.standardDateAndTimeFormatter.dateFromString(endsBox.text)!
        event.notes = notesView.text
        
        EventManager.sharedInstance.creationDelegate = self
        EventManager.sharedInstance.createEventInEventEditVC(event, viewController: self)
    }
    
    //MARK:- UITextFieldDelegate

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
    
    //MARK:- LocationSelectionDelegate
    
    func locationSelected(address: String) {
        locationBox.text = address
        //set lat and long to nil in case coordinates are never successfully calculated. We don't want the coordiantes of a previous address being used. If coordinates are calculated they will be overwritten.
        locationLatitude = nil
        locationLongitude = nil
    }
    
    func coordinatesCalculated(#address: String, coordinates: CLLocationCoordinate2D) {
        if address == locationBox.text {
            locationLatitude = coordinates.latitude
            locationLongitude = coordinates.longitude
        }
    }
    
    //MARK:- EventCreationDelegate
    
    func eventCreated(#event: EKEvent, wasSaved: Bool) {
        if wasSaved {
            saveDetailsFollowingCreationOfEvent(event)
        }
    }
    
    //MARK:- IBActions
    
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
    
    //MARK:- Core Data Changers
    
    private func saveDetailsFollowingCreationOfEvent(event: EKEvent) {
        let managedContext = Common.managedContext
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
    
    private func saveDetailsFromControlData() {
        let managedContext = Common.managedContext
        let interview = createOrLoadInterview()
        
        interview.eventID = ""
        interview.title = titleBox.text
        interview.starts = Common.standardDateAndTimeFormatter.dateFromString(startsBox.text)!
        interview.ends = Common.standardDateAndTimeFormatter.dateFromString(endsBox.text)!
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
    
    private func deleteInterview() {
        if loadedInterview != nil {
            let mutableInterviews = loadedBasic.interviews.mutableCopy() as! NSMutableSet
            mutableInterviews.removeObject(loadedInterview!)
            loadedBasic.interviews = mutableInterviews
            
            var error: NSError?
            if !Common.managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    private func createOrLoadInterview() -> JobInterview {
        var interview: JobInterview
        if loadedInterview != nil {
            interview = loadedInterview!
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            interview = NSEntityDescription.insertNewObjectForEntityForName("JobInterview", inManagedObjectContext: managedContext) as! JobInterview
            let interviewLocation = NSEntityDescription.insertNewObjectForEntityForName("JobLocation", inManagedObjectContext: managedContext) as! JobLocation
            managedContext.insertObject(interview)
            managedContext.insertObject(interviewLocation)
            
            loadedBasic.interviews.setByAddingObject(interview)
            interview.basic = loadedBasic
            interview.location = interviewLocation
        }
        return interview
    }
}