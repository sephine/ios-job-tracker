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
    //CompanyDetails should only be used in the intial set up of the cells, otherwise Company should be used and it will automatically choose the right cell type.
    case Company, CompanyDetails, Location, CompanyWebsite, JobListing, GlassdoorLink, Notes
}

class ShowDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var loadedBasic: JobBasic!
    var cellTypeArray: [(type: ShowCellType, interview: JobInterview?, website: String?)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //stops an inset being added when the app is brought back from being in the background.
        automaticallyAdjustsScrollViewInsets = false
        
        //initially load all types of resizable cells so they can successfully have their heights changed when the table is reloaded. This data will never show.
        loadTableWithDummyData()
    }
    
    func loadTableWithDummyData() {
        cellTypeArray = []
        cellTypeArray.append(type: .CompanyDetails, interview: nil, website: nil)
        cellTypeArray.append(type: .Location, interview: nil, website: nil)
        cellTypeArray.append(type: .Notes, interview: nil, website: nil)
        tableView.estimatedRowHeight = 44.0 //69.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.layoutIfNeeded()
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //TODO check toolbar is needed
        self.navigationController?.toolbarHidden = false
        reloadCellTypeArray()
    }
    
    func reloadCellTypeArray() {
        let stage = Stage(rawValue: loadedBasic.stage.integerValue)!
        title = loadedBasic.company
        
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
        let notes = loadedBasic.details.notes
        if !notes.isEmpty {
            cellTypeArray.append(type: .Notes, interview: nil, website: nil)
        }
        
        tableView.reloadData()
        
        //adding an empty footer ensures that the table view doesn't show empty rows
        tableView.tableFooterView = UIView(frame: CGRectZero)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.toolbarHidden = true
        self.view.endEditing(false)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 4
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Job Details"
        case 1:
            return "Application"
        case 2:
            return "Interviews"
        default:
            return "Offers"
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return cellTypeArray.count
        case 1:
            return 1
        case 2:
            return loadedBasic.interviews.count + 1
        default:
            //TODO
            return 0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cellType = cellTypeArray[indexPath.row].type
            switch cellType {
            case .Company:
                return getCompanyCell()
            case .CompanyDetails:
                return getCompanyDetailsCell()
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
            }
        case 1:
            if loadedBasic.application == nil {
                return getAddApplicationCell()
            }
            return getViewApplicationCell()
        default:
            if indexPath.row == 0 {
                return getAddInterviewCell()
            }
            let interview = loadedBasic.orderedInterviews[indexPath.row - 1]
            return getViewInterviewCell(interview)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(false)
        switch indexPath.section {
        case 0:
            let selectedTuple = cellTypeArray[indexPath.row]
            let website = selectedTuple.website
            if website != nil && website != "" {
                performSegueWithIdentifier("showWeb", sender: indexPath)
            }
        case 1:
            performSegueWithIdentifier("editApplication", sender: self)
        default:
            if indexPath.row == 0 {
                performSegueWithIdentifier("editInterview", sender: nil)
            } else {
                let interview = loadedBasic.orderedInterviews[indexPath.row - 1]
                if interview.eventID.isEmpty {
                    performSegueWithIdentifier("editInterview", sender: indexPath)
                } else {
                    segueToCalendarEventForInterview(interview)
                }
            }
        }
    }
    
    func segueToCalendarEventForInterview(interview: JobInterview) {
        EventManager.sharedInstance.loadEventInEventEditVC(interviewToUpdate: interview, viewController: self)
    }
    
    func getCompanyCell() -> ShowResultCell {
        let stage = Stage(rawValue: loadedBasic.stage.integerValue)!
        let title = loadedBasic.title as String
        let salary = loadedBasic.details.salary as NSNumber?
        let dueDate = loadedBasic.details.dueDate as NSDate?
        
        if title.isEmpty && salary == nil && dueDate == nil {
            let cell = tableView.dequeueReusableCellWithIdentifier("showCompanyCell") as ShowResultCell
            
            cell.mainLabel.text = stage.title
            return cell
        } else {
            return getCompanyDetailsCell()
        }
    }
    
    func getCompanyDetailsCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showCompanyWithDetailCell") as ShowResultCell
        
        let stage = Stage(rawValue: loadedBasic.stage.integerValue)!
        let title = loadedBasic.title as String
        let salary = loadedBasic.details.salary as NSNumber?
        let dueDate = loadedBasic.details.dueDate as NSDate?
        
        var salaryString: String?
        if salary != nil {
            salaryString = Common.standardCurrencyFormatter().stringFromNumber(salary!)
        }
        
        var dueDateString: String?
        if dueDate != nil {
            dueDateString = Common.standardDateFormatter().stringFromDate(dueDate!)
        }
        
        var detailsArray = [String]()
        if !title.isEmpty {
            detailsArray.append(title)
        }
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
    
    func getLocationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showLocationCell") as ShowResultCell
        cell.mainLabel.text = loadedBasic.location.address
        return cell
    }
    
    func getWebsiteCell(text: String) -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showWebsiteCell") as ShowResultCell
        cell.mainLabel.text = text
        return cell
    }
    
    func getGlassdoorCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showGlassdoorCell") as UITableViewCell
        return cell
    }
    
    func getNotesCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showNotesCell") as ShowResultCell
        cell.secondaryLabel!.text = loadedBasic.details.notes
        return cell
    }
    
    func getAddApplicationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showAddStageCell") as ShowResultCell
        cell.mainLabel.text = "Add Application"
        return cell
    }
    
    func getViewApplicationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let dateSent = loadedBasic.application?.dateSent
        let notes = loadedBasic.application?.notes
        
        var dateSentString: String?
        if dateSent != nil {
            dateSentString = Common.standardDateFormatter().stringFromDate(dateSent!)
        }
        
        var detailsArray = [String]()
        if dateSentString != nil {
            detailsArray.append("Sent: \(dateSentString!)")
        }
        if notes != nil && !notes!.isEmpty {
            detailsArray.append("\(notes!)")
        }
        
        let detailsString = join("\n", detailsArray)
        cell.mainLabel.text = detailsString
        return cell
    }
    
    func getAddInterviewCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showAddStageCell") as ShowResultCell
        cell.mainLabel.text = "Add Interview"
        return cell
    }
    
    func getViewInterviewCell(interview: JobInterview) -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let startsString = Common.standardDateAndTimeFormatter().stringFromDate(interview.starts)
        let endsString = Common.standardDateAndTimeFormatter().stringFromDate(interview.ends)
        
        var detailsArray = [String]()
        detailsArray.append(interview.title)
        
        let address = interview.location.address
        if !address.isEmpty {
            detailsArray.append(address)
        }
        
        detailsArray.append("Starts: \(startsString)")
        detailsArray.append("Ends: \(endsString)")
        
        if !interview.notes.isEmpty {
            detailsArray.append(interview.notes)
        }
        
        let detailsString = join("\n", detailsArray)
        cell.mainLabel.text = detailsString
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showWeb" {
            let indexPath = sender as NSIndexPath
            let website = cellTypeArray[indexPath.row].website
            let destination = segue.destinationViewController as WebViewController
            destination.website = website
        } else if segue.identifier == "showMap" {
            let destination = segue.destinationViewController as MapViewController
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
        }
    }
}

//TODO some of the stored data is empty strings and sometimes nil, tidy it up.
