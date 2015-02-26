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

class EditInterviewViewController: UITableViewController, UITextFieldDelegate, LocationSelectionDelegate {

    @IBOutlet weak var titleBox: UITextField!
    @IBOutlet weak var locationBox: UITextField!
    @IBOutlet weak var startsBox: UITextField!
    @IBOutlet weak var endsBox: UITextField!
    @IBOutlet weak var calendarBox: UITextField!
    @IBOutlet weak var notesView: UITextView!

    var loadedBasic: JobBasic!
    var interviewNumberToLoad: Int?
    
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
        setUpDatePickers()
        
        if interviewNumberToLoad == nil {
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
                title = "Edit Interview \(interviewNumberToLoad!)"
            }
            let interviews = loadedBasic.interviews
            for interviewItem in interviews {
                let interviewItem = interviewItem as JobInterview
                if interviewItem.interviewNumber == interviewNumberToLoad! {
                    loadedInterview = interviewItem
                    break
                }
            }
            
            if !loadedInterview!.eventID.isEmpty {
                setControlValuesToDataLoadedFromCalendar()
            } else {
                setControlValuesToLocallySavedData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
    
    func setControlValuesToDataLoadedFromCalendar() {
        //TODO
    }
    
    func setControlValuesToLocallySavedData() {
        titleBox.text = loadedInterview!.title
        locationBox.text = loadedInterview!.interviewLocation.address
        locationLatitude = loadedInterview!.interviewLocation.latitude
        locationLongitude = loadedInterview!.interviewLocation.longitude
        
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
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        saveDetails()
        navigationController?.popViewControllerAnimated(true)
    }

    func saveDetails() {
        //TODO
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        var interview: JobInterview
        var interviewLocation: JobLocation
        if loadedInterview != nil {
            interview = loadedInterview!
            interviewLocation = loadedInterview!.interviewLocation
        } else {
            interview = NSEntityDescription.insertNewObjectForEntityForName("JobInterview", inManagedObjectContext: managedContext) as JobInterview
            interviewLocation = NSEntityDescription.insertNewObjectForEntityForName("JobLocation", inManagedObjectContext: managedContext) as JobLocation
            managedContext.insertObject(interview)
            managedContext.insertObject(interviewLocation)
            
            let newInterviewNumber = loadedBasic.highestInterviewNumber.integerValue + 1
            loadedBasic.highestInterviewNumber = newInterviewNumber
            interview.interviewNumber = newInterviewNumber

            loadedBasic.interviews.setByAddingObject(interview)
            interview.basic = loadedBasic
            interview.interviewLocation = interviewLocation
            loadedBasic.details.interviewStarted = true
            loadedBasic.stage = Stage.Interview.rawValue
        }
        
        interview.title = titleBox.text
        interview.notes = notesView.text
        
        interview.starts = dateFormatter.dateFromString(startsBox.text)!
        interview.ends = dateFormatter.dateFromString(endsBox.text)!
        
        interviewLocation.address = locationBox.text!
        interviewLocation.latitude = locationLatitude
        interviewLocation.longitude = locationLongitude
        
        //TODO if calendar is not none set eventID to empty, else
        interview.eventID = saveToCalendarAndGetEventID()
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }

    }
    
    func saveToCalendarAndGetEventID() -> String {
        //TODO
        return ""
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