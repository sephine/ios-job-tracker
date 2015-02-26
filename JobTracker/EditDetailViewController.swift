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
    
    var goToDetailsSectionData: [(title: String, segueID: String, interviewNumber: Int?)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Job"
        
        //the first section of the tableview is static, the second will be set up dynamically
        setUpGoToDetailsSectionData()
        
        datePickerView.datePickerMode = UIDatePickerMode.Date
        datePickerView.addTarget(self, action: "updateDate", forControlEvents: UIControlEvents.ValueChanged)
        dueDateBox.inputView = datePickerView
        
        //TODO set button image
        
        if let basic = loadedBasic {
            title = "Edit Job"
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
    
    func setUpGoToDetailsSectionData() {
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "goToDetailsCell")
        
        if loadedBasic != nil {
            if loadedBasic!.details.appliedStarted {
                goToDetailsSectionData.append(title: "Application Details", segueID: "editApplication", interviewNumber: nil)
            }
            if loadedBasic!.details.interviewStarted {
                let numberOfInterviews = loadedBasic!.highestInterviewNumber.integerValue
                if numberOfInterviews == 1 {
                    let interviewNumber: Int? = 1
                    goToDetailsSectionData.append(title: "Interview Details", segueID: "editInterview", interviewNumber: interviewNumber)
                } else {
                    for i in 1...numberOfInterviews {
                        let interviewNumber: Int? = i
                        let position = Common.positionStringFromNumber(i)!
                        goToDetailsSectionData.append(title: "\(position) Interview Details", segueID: "editInterview", interviewNumber: interviewNumber)
                    }
                }
            }
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        let i = goToDetailsSectionData.count
        return goToDetailsSectionData.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("goToDetailsCell") as UITableViewCell
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        let detailsTuple = goToDetailsSectionData[indexPath.row]
        cell.textLabel!.text = detailsTuple.title
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 {
            let detailsTuple = goToDetailsSectionData[indexPath.row]
            performSegueWithIdentifier(detailsTuple.segueID, sender: indexPath)
        }
    }
    
    /*override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //check if the details cells at the bottom should be hidden
        let hideApplicationDetails = loadedBasic == nil || !loadedBasic!.details.appliedStarted
        if indexPath.section == 1 && (indexPath.row == 0 && hideApplicationDetails) {
            return 0
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }*/
    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        if textField.tag == companyBoxTag {
            companyJustCleared = true
        } else if textField.tag == locationBoxTag {
            locationJustCleared = true
            locationLatitude = nil
            locationLongitude = nil
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
        if !locationBox.text.isEmpty {
            locationLatitude = coordinates.latitude
            locationLongitude = coordinates.longitude
        }
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
        } else if segue.identifier == "editInterview" {
            let destination = segue.destinationViewController as EditInterviewViewController
            destination.loadedBasic = loadedBasic
            let indexPath = sender as NSIndexPath
            let detailsTuple = goToDetailsSectionData[indexPath.row]
            destination.interviewNumberToLoad = detailsTuple.interviewNumber
        } else if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
}

//TODO check for empty text boxes
