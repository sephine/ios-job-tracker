//
//  ShowDetailsViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/10/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

enum ShowCellType {
    case Company, Location, CompanyWebsite, JobListing, GlassdoorLink, Notes, Contacts
}

enum ShowSectionType {
    case Basic, Application, Interview, Offer, Rejected
}

class ShowDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ShowInterviewResultCellDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rejectOrRestoreButton: UIBarButtonItem!
    
    var loadedBasic: JobBasic!
    
    private var cellTypeArray: [(type: ShowCellType, interview: JobInterview?, website: String?)] = []
    private var sectionTypeArray: [ShowSectionType] = []
    private var stage: Stage {
        return Stage(rawValue: loadedBasic.stage.integerValue)!
    }
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //stops an inset being added when the app is brought back from being in the background.
        automaticallyAdjustsScrollViewInsets = false

        //set up the table view so it resizes cells properly
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        reloadSectionTypeArray()
        reloadCellTypeArray()
        
        //individually reloading the sections seems to solve the problem where cells that appear off the screen aren't the correct height.
        for i in 0..<sectionTypeArray.count {
            let indexSet = NSIndexSet(index: i)
            tableView.reloadSections(indexSet, withRowAnimation: .None)
        }
        
        checkForUpdatedInterviewEvents()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        title = loadedBasic.company
        if stage == .Rejected {
            rejectOrRestoreButton.title = "Restore"
        } else {
            rejectOrRestoreButton.title = "Reject"
        }
        
        reloadSectionTypeArray()
        reloadCellTypeArray()
        tableView.reloadData()
        
        self.navigationController?.toolbarHidden = false
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.toolbarHidden = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showWeb" {
            let indexPath = sender as NSIndexPath
            let website = cellTypeArray[indexPath.row].website
            let destination = segue.destinationViewController as WebViewController
            destination.website = website
        } else if segue.identifier == "showMap" {
            let destination = segue.destinationViewController as MapViewController
            if sender is JobInterview {
                let interview = sender as JobInterview
                destination.location = interview.location
                destination.locationTitle = interview.title
            } else {
                destination.location = loadedBasic.location
                destination.locationTitle = loadedBasic.company
            }
        } else if segue.identifier == "showContacts" {
            let destination = segue.destinationViewController as ShowContactsViewController
            destination.loadedBasic = loadedBasic
        } else if segue.identifier == "editJob" {
            let destination = segue.destinationViewController as EditDetailViewController
            destination.loadedBasic = loadedBasic
        } else if segue.identifier == "editApplication" {
            let destination = segue.destinationViewController as EditApplicationViewController
            destination.loadedBasic = loadedBasic
        } else if segue.identifier == "editInterview" {
            let destination = segue.destinationViewController as EditInterviewViewController
            destination.loadedBasic = loadedBasic
            if sender is NSIndexPath {
                let indexPath = sender as NSIndexPath
                let interview = loadedBasic.orderedInterviews[indexPath.row - 1]
                destination.loadedInterview = interview
            }
        } else if segue.identifier == "editOffer" {
            let destination = segue.destinationViewController as EditOfferViewController
            destination.loadedBasic = loadedBasic
        } else if segue.identifier == "editReject" {
            let destination = segue.destinationViewController as EditRejectViewController
            destination.loadedBasic = loadedBasic
        }
    }

    //MARK:-
    
    //event dates etc might have been changed since last opened.
    private func checkForUpdatedInterviewEvents() {
        for interview in loadedBasic.interviews {
            let interview = interview as JobInterview
            EventManager.sharedInstance.syncInterviewWithCalendarEvent(interview: interview)
        }
    }
    
    private func reloadSectionTypeArray() {
        sectionTypeArray = []
        sectionTypeArray.append(.Basic)
        if stage == .Rejected {
            //there should be no option to add applications etc when rejected, should just show current ones.
            if loadedBasic.application != nil {
                sectionTypeArray.append(.Application)
            }
            if loadedBasic.interviews.count != 0 {
                sectionTypeArray.append(.Interview)
            }
            if loadedBasic.offer != nil {
                sectionTypeArray.append(.Offer)
            }
            sectionTypeArray.append(.Rejected)
        } else {
            sectionTypeArray.append(.Application)
            sectionTypeArray.append(.Interview)
            sectionTypeArray.append(.Offer)
        }
    }
    
    private func reloadCellTypeArray() {
        cellTypeArray = []
        cellTypeArray.append(type: .Company, interview: nil, website: nil)
        
        let address = loadedBasic.location.address
        if !address.isEmpty {
            cellTypeArray.append(type: .Location, interview: nil, website: nil)
        }
        
        let website: String? = loadedBasic.details.website
        if !website!.isEmpty {
            cellTypeArray.append(type: .CompanyWebsite, interview: nil, website: website)
        }
        
        let listing: String? = loadedBasic.details.jobListing
        if !listing!.isEmpty {
            cellTypeArray.append(type: .JobListing, interview: nil, website: listing)
        }
        
        let glassdoor: String? = loadedBasic.details.glassdoorLink
        if !glassdoor!.isEmpty {
            cellTypeArray.append(type: .GlassdoorLink, interview: nil, website: glassdoor)
        }
        cellTypeArray.append(type: .Contacts, interview: nil, website: nil)
        let notes = loadedBasic.details.notes
        if !notes.isEmpty {
            cellTypeArray.append(type: .Notes, interview: nil, website: nil)
        }
    }
    
    
    //MARK:- UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTypeArray.count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = sectionTypeArray[section]
        switch sectionType {
        case .Basic:
            return "Job Details"
        case .Application:
            return "Application"
        case .Interview:
            return "Interviews"
        case .Offer:
            return "Offer"
        case .Rejected:
            return "Rejection"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sectionTypeArray[section]
        switch sectionType {
        case .Basic:
            return cellTypeArray.count
        case .Application:
            return 1
        case .Interview:
            if stage == .Rejected {
                return loadedBasic.interviews.count
            }
            return loadedBasic.interviews.count + 1
        case .Offer:
            return 1
        case .Rejected:
            return 1
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionType = sectionTypeArray[indexPath.section]
        switch sectionType {
        case .Basic:
            let cellType = cellTypeArray[indexPath.row].type
            switch cellType {
            case .Company:
                return getCompanyCell()
            case .Location:
                return getLocationCell()
            case .CompanyWebsite:
                return getWebsiteCell("Company Website")
            case .JobListing:
                return getWebsiteCell("Job Listing")
            case .GlassdoorLink:
                return getGlassdoorCell()
            case .Notes:
                return getNotesCell()
            case .Contacts:
                return getContactsCell()
            }
        case .Application:
            if loadedBasic.application == nil {
                return getAddApplicationCell()
            }
            return getViewApplicationCell()
        case .Interview:
            if stage == .Rejected {
                let interview = loadedBasic.orderedInterviews[indexPath.row]
                return getViewInterviewCell(interview)
            }
            if indexPath.row == 0 {
                return getAddInterviewCell()
            }
            let interview = loadedBasic.orderedInterviews[indexPath.row - 1]
            return getViewInterviewCell(interview)
        case .Offer:
            if loadedBasic.offer == nil {
                return getAddOfferCell()
            }
            return getViewOfferCell()
        case .Rejected:
            return getViewRejectedCell()
        }
    }
    
    //MARK:-
    
    private func getCompanyCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showCompanyCell") as ShowResultCell
        
        let stage = Stage(rawValue: loadedBasic.stage.integerValue)!
        let company = loadedBasic.company
        let title = loadedBasic.title as String
        let salary = loadedBasic.details.salary as NSNumber?
        let dueDate = loadedBasic.details.dueDate as NSDate?
        
        var salaryString: String?
        if salary != nil {
            salaryString = Common.standardCurrencyFormatter.stringFromNumber(salary!)
        }
        
        var dueDateString: String?
        if dueDate != nil {
            dueDateString = Common.standardDateFormatter.stringFromDate(dueDate!)
        }
        
        var detailsArray = [String]()
        if !title.isEmpty {
            detailsArray.append(title)
        }
        detailsArray.append(company)
        if salaryString != nil {
            detailsArray.append(salaryString!)
        }
        if dueDateString != nil {
            detailsArray.append("Due: \(dueDateString!)")
        }
        
        let detailsString = join("\n", detailsArray)
        
        cell.mainLabel.text = stage.title
        cell.secondaryLabel!.text = detailsString
        return cell
    }
    
    private func getLocationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showLocationCell") as ShowResultCell
        cell.mainLabel.text = loadedBasic.location.address
        return cell
    }
    
    private func getWebsiteCell(text: String) -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showWebsiteCell") as ShowResultCell
        cell.mainLabel.text = text
        return cell
    }
    
    private func getGlassdoorCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showGlassdoorCell") as UITableViewCell
        return cell
    }
    
    private func getNotesCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showNotesCell") as ShowResultCell
        cell.secondaryLabel!.text = loadedBasic.details.notes
        return cell
    }
    
    private func getContactsCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showContactsCell") as ShowResultCell
        
        let numberOfContacts = loadedBasic.contacts.count
        if numberOfContacts == 0 {
            cell.secondaryLabel!.text = "None"
        } else {
            cell.secondaryLabel!.text = "\(numberOfContacts) Contacts"
        }
        return cell
    }
    
    private func getAddApplicationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showAddStageCell") as ShowResultCell
        cell.mainLabel.text = "Add Application"
        return cell
    }
    
    private func getViewApplicationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let dateSent = loadedBasic.application!.dateSent
        let dateSentString = Common.standardDateFormatter.stringFromDate(dateSent)
        let notes = loadedBasic.application!.notes
        
        var detailsArray = [String]()
        detailsArray.append("Sent: \(dateSentString)")
        if !notes.isEmpty {
            detailsArray.append("\(notes)")
        }
        
        let detailsString = join("\n", detailsArray)
        cell.mainLabel.text = detailsString
        return cell
    }
    
    private func getAddInterviewCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showAddStageCell") as ShowResultCell
        cell.mainLabel.text = "Add Interview"
        return cell
    }
    
    private func getViewInterviewCell(interview: JobInterview) -> UITableViewCell {
        if !interview.location.address.isEmpty {
            return getViewInterviewWithAddressCell(interview)
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let startsString = Common.standardDateAndTimeFormatter.stringFromDate(interview.starts)
        let endsString = Common.standardDateAndTimeFormatter.stringFromDate(interview.ends)
        
        var detailsArray = [String]()
        detailsArray.append(interview.title)
        detailsArray.append("Starts: \(startsString)")
        detailsArray.append("Ends: \(endsString)")
        
        if !interview.notes.isEmpty {
            detailsArray.append(interview.notes)
        }
        
        let detailsString = join("\n", detailsArray)
        cell.mainLabel.text = detailsString
        return cell
    }
    
    private func getViewInterviewWithAddressCell(interview: JobInterview) -> ShowInterviewResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showInterviewWithAddressCell") as ShowInterviewResultCell
        cell.interview = interview
        cell.delegate = self
        
        let startsString = Common.standardDateAndTimeFormatter.stringFromDate(interview.starts)
        let endsString = Common.standardDateAndTimeFormatter.stringFromDate(interview.ends)
        
        var detailsArray = [String]()
        detailsArray.append("Starts: \(startsString)")
        detailsArray.append("Ends: \(endsString)")
        if !interview.notes.isEmpty {
            detailsArray.append(interview.notes)
        }
        let detailsString = join("\n", detailsArray)
        
        cell.titleLabel.text = interview.title
        cell.addressButton.setTitle(interview.location.address, forState: UIControlState.Normal)
        cell.secondaryLabel.text = detailsString
        return cell
    }
    
    private func getAddOfferCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showAddStageCell") as ShowResultCell
        cell.mainLabel.text = "Add Offer"
        return cell
    }
    
    private func getViewOfferCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let dateReceived = loadedBasic.offer!.dateReceived
        let dateReceivedString = Common.standardDateFormatter.stringFromDate(dateReceived)
        let salary = loadedBasic.offer!.salary as NSNumber?
        let notes = loadedBasic.offer!.notes
        
        var salaryString: String?
        if salary != nil {
            salaryString = Common.standardCurrencyFormatter.stringFromNumber(salary!)
        }
        
        var detailsArray = [String]()
        detailsArray.append("Received: \(dateReceivedString)")
        if salaryString != nil {
            detailsArray.append(salaryString!)
        }
        if !notes.isEmpty {
            detailsArray.append("\(notes)")
        }
        
        let detailsString = join("\n", detailsArray)
        cell.mainLabel.text = detailsString
        return cell
    }
    
    private func getViewRejectedCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let dateRejected = loadedBasic.rejected!.dateRejected
        let dateRejectedString = Common.standardDateFormatter.stringFromDate(dateRejected)
        let notes = loadedBasic.rejected!.notes
        
        var detailsArray = [String]()
        detailsArray.append("Rejected: \(dateRejectedString)")
        if !notes.isEmpty {
            detailsArray.append("\(notes)")
        }
        
        let detailsString = join("\n", detailsArray)
        cell.mainLabel.text = detailsString
        return cell
    }
    
    //MARK:- UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sectionType = sectionTypeArray[indexPath.section]
        switch sectionType {
        case .Basic:
            let selectedTuple = cellTypeArray[indexPath.row]
            let website = selectedTuple.website
            if website != nil && website != "" {
                performSegueWithIdentifier("showWeb", sender: indexPath)
            }
        case .Application:
            performSegueWithIdentifier("editApplication", sender: self)
        case .Interview:
            var offset = 0
            if stage != .Rejected {
                if indexPath.row == 0 {
                    performSegueWithIdentifier("editInterview", sender: nil)
                    return
                }
                offset = 1
            }
            let interview = loadedBasic.orderedInterviews[indexPath.row - offset]
            if interview.eventID.isEmpty {
                performSegueWithIdentifier("editInterview", sender: indexPath)
            } else {
                segueToCalendarEventForInterview(interview)
            }
        case .Offer:
            performSegueWithIdentifier("editOffer", sender: self)
        case .Rejected:
            performSegueWithIdentifier("editReject", sender: self)
        }
    }
    
    //MARK:-
    
    private func segueToCalendarEventForInterview(interview: JobInterview) {
        EventManager.sharedInstance.loadEventInEventEditVC(interviewToUpdate: interview, viewController: self)
    }
    
    //MARK:- ShowInterviewResultCellDelegate
    
    func addressButtonSelectedForInterview(interview: JobInterview) {
        performSegueWithIdentifier("showMap", sender: interview)
    }
    
    //MARK:- IBActions
    
    @IBAction func rejectOrRestoreButtonClicked(sender: UIBarButtonItem) {
        if stage != .Rejected {
            performSegueWithIdentifier("editReject", sender: self)
        } else {
            restoreJob()
        }
    }
    
    //MARK:- Core Data Changers
    
    private func restoreJob() {
        loadedBasic.rejected = nil
        
        var error: NSError?
        if !Common.managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
        
        reloadSectionTypeArray()
        reloadCellTypeArray()
        tableView.reloadData()
        rejectOrRestoreButton.title = "Reject"
    }
}

//TODO: some of the stored data is empty strings and sometimes nil, tidy it up.




