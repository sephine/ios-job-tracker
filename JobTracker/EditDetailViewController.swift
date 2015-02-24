//
//  JobDetailViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/5/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class EditDetailViewController: UITableViewController, UITextFieldDelegate, CompanySelectionDelegate, LocationSelectionDelegate {

    @IBOutlet weak var companyBox: UITextField!
    @IBOutlet weak var websiteBox: UITextField!
    @IBOutlet weak var positionBox: UITextField!
    @IBOutlet weak var salaryBox: UITextField!
    @IBOutlet weak var locationBox: UITextField!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var listingBox: UITextField!
    @IBOutlet weak var dueDateBox: UITextField!
    @IBOutlet weak var notesView: UITextView!
    
    let companyBoxTag = 100
    let salaryBoxTag = 101
    let locationBoxTag = 102
    var companyJustCleared = false
    var locationJustCleared = false
    
    var loadedBasic: JobBasic?
    var salary: NSNumber?
    var glassdoorLink = ""
    var locationLatitude: NSNumber?
    var locationLongitude: NSNumber?
    let datePickerView = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Job Detail"
        
        datePickerView.datePickerMode = UIDatePickerMode.Date
        datePickerView.addTarget(self, action: "updateDate", forControlEvents: UIControlEvents.ValueChanged)
        dueDateBox.inputView = datePickerView
        
        //TODO set button image
        
        if let basic = loadedBasic {
            companyBox.text = basic.company
            websiteBox.text = basic.details.website
            positionBox.text = basic.title
            locationBox.text = basic.location.address
            locationLatitude = basic.location.latitude
            locationLongitude = basic.location.longitude
            listingBox.text = basic.details.jobListing
            glassdoorLink = basic.details.glassdoorLink
            notesView.text = basic.details.notes
            
            let date = basic.details.dueDate as NSDate?
            if date == nil {
                dueDateBox.text = ""
            } else {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
                dueDateBox.text = dateFormatter.stringFromDate(date!)
                datePickerView.date = date!
            }
            
            salary = basic.details.salary as NSNumber?
            if salary == nil {
                salaryBox.text = ""
            } else {
                let salaryFormatter = NSNumberFormatter()
                salaryFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                salaryBox.text = salaryFormatter.stringFromNumber(salary!)
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
        if textField.tag == companyBoxTag {
            companyJustCleared = true
        } else if textField.tag == locationBoxTag {
            locationJustCleared = true
        }
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField.tag == companyBoxTag {
            if companyJustCleared {
                companyJustCleared = false
            } else {
                performSegueWithIdentifier("findCompany", sender: self)
            }
            return false
        } else if textField.tag == locationBoxTag {
            if locationJustCleared {
                locationJustCleared = false
            } else {
                performSegueWithIdentifier("findLocation", sender: self)
            }
            return false
        }
        return true
    }
    
    //only called by salary text field, company and location text field doesn't begin editing (the rest don't have this class set as delegate.
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let newSalary = salaryBox.text + string
        let expression = "^\\d+\\.?\\d{0,2}$"
        let regex = NSRegularExpression(pattern: expression, options: nil, error: nil)
        let numberOfMatches = regex?.numberOfMatchesInString(newSalary, options: nil, range: NSMakeRange(0, countElements(newSalary)))
        if numberOfMatches == 0 {
            return false
        }
        salary = (newSalary as NSString).doubleValue
        return true
    }
    
    //see above
    func textFieldDidBeginEditing(textField: UITextField) {
        if salary != nil {
            salaryBox.text = salary!.stringValue
        }
    }
    
    //see above
    func textFieldDidEndEditing(textField: UITextField) {
        if salaryBox.text == "" {
            salary = nil
            return
        }
        salary = (salaryBox.text as NSString).doubleValue
            
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        salaryBox.text = formatter.stringFromNumber(salary!)
    }
    
    func companySelected(company: String, website: String, glassdoorLink: String) {
        companyBox.text = company
        websiteBox.text = website
        self.glassdoorLink = glassdoorLink
    }
    
    func locationSelected(address: String) {
        locationBox.text = address
    }
    
    func coordinatesCalculated(coordinates: CLLocationCoordinate2D) {
        locationLatitude = coordinates.latitude
        locationLongitude = coordinates.longitude
    }
    
    @IBAction func updateDate() {
        let date = datePickerView.date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dueDateBox.text = dateFormatter.stringFromDate(date)
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        if companyBox.text.isEmpty {
            let alert = UIAlertView(title: "Save Failed", message: "Please specify a company.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else {
            saveDetails()
            navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    func saveDetails() {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        var basic: JobBasic
        var details: JobDetail
        var location: JobLocation
        if loadedBasic != nil {
            basic = loadedBasic!
            details = basic.details
            location = basic.location
        } else {
            basic = NSEntityDescription.insertNewObjectForEntityForName("JobBasic", inManagedObjectContext: managedContext) as JobBasic
            details = NSEntityDescription.insertNewObjectForEntityForName("JobDetail", inManagedObjectContext: managedContext) as JobDetail
            location = NSEntityDescription.insertNewObjectForEntityForName("JobLocation", inManagedObjectContext: managedContext) as JobLocation
            managedContext.insertObject(basic)
            managedContext.insertObject(details)
            managedContext.insertObject(location)
            basic.stage = Stage.Potential.rawValue
            details.appliedStarted = false
            details.interviewStarted = false
            details.decisionStarted = false
            details.offerStarted = false
            basic.details = details
            basic.location = location
            details.basic = basic
            location.basic = basic
        }
        
        basic.company = companyBox.text!
        basic.title = positionBox.text!
        
        details.website = websiteBox.text!
        details.salary = salary
        details.jobListing = listingBox.text
        details.glassdoorLink = glassdoorLink
        details.notes = notesView.text
        
        location.address = locationBox.text!
        location.latitude = locationLatitude
        location.longitude = locationLongitude
        
        if dueDateBox.text!.isEmpty {
            details.dueDate = nil
        } else {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            details.dueDate = dateFormatter.dateFromString(dueDateBox.text!)
        }
        
        loadedBasic = basic
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "findCompany" {
            let destination = segue.destinationViewController as CompanyTableViewController
            destination.delegate = self
        } else if segue.identifier == "findLocation" {
            let destination = segue.destinationViewController as LocationTableViewController
            destination.delegate = self
        } else if segue.identifier == "editApplication" {
            let destination = segue.destinationViewController as EditApplicationViewController
            destination.loadedBasic = loadedBasic
        } else if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
}

//TODO check for empty text boxes
