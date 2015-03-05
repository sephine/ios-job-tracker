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
    case Company, CompanyDetails, Location, CompanyWebsite, JobListing, GlassdoorLink, Notes, Applied, Interview
}

class ShowDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StageSelectionDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var hiddenTextField: UITextField!
    
    var stageVC: StageViewController!
    //var stageView: UIView!
    var loadedBasic: JobBasic!
    var cellTypeArray: [(type: ShowCellType, interviewNumber: Int?, website: String?)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //stops an inset being added when the app is brought back from being in the background.
        automaticallyAdjustsScrollViewInsets = false
        
        stageVC = storyboard?.instantiateViewControllerWithIdentifier("stageView") as StageViewController
        stageVC.delegate = self
        stageVC.loadedBasic = loadedBasic
        
        hiddenTextField.hidden = true
        hiddenTextField.inputView = stageVC.view
        
        //initially load all types of resizable cells so they can successfully have their heights changed when the table is reloaded. This data will never show.
        loadTableWithDummyData()
    }
    
    func loadTableWithDummyData() {
        cellTypeArray = []
        cellTypeArray.append(type: .CompanyDetails, interviewNumber: nil, website: nil)
        cellTypeArray.append(type: .Location, interviewNumber: nil, website: nil)
        cellTypeArray.append(type: .Notes, interviewNumber: nil, website: nil)
        cellTypeArray.append(type: .Applied, interviewNumber: nil, website: nil)
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
        
        self.navigationController?.toolbarHidden = false
        reloadCellTypeArray()
    }
    
    func reloadCellTypeArray() {
        let stage = Stage(rawValue: loadedBasic.stage.integerValue)!
        title = stage.title
        
        cellTypeArray = []
        cellTypeArray.append(type: .Company, interviewNumber: nil, website: nil)
        
        let address = loadedBasic.location.address
        if !address.isEmpty {
            cellTypeArray.append(type: .Location, interviewNumber: nil, website: nil)
        }
        
        let website: String? = loadedBasic.details.website
        if !website!.isEmpty {
            cellTypeArray.append(type: .CompanyWebsite, interviewNumber: nil, website: website)
        }
        
        let listing: String? = loadedBasic.details.jobListing
        if !listing!.isEmpty {
            cellTypeArray.append(type: .JobListing, interviewNumber: nil, website: listing)
        }
        
        let glassdoor: String? = loadedBasic.details.glassdoorLink
        if !glassdoor!.isEmpty {
            cellTypeArray.append(type: .GlassdoorLink, interviewNumber: nil, website: glassdoor)
        }
        let notes = loadedBasic.details.notes
        if !notes.isEmpty {
            cellTypeArray.append(type: .Notes, interviewNumber: nil, website: nil)
        }
        let dateSent = loadedBasic.application?.dateSent
        let appliedNotes = loadedBasic.application?.notes
        if dateSent != nil || (appliedNotes != nil && !appliedNotes!.isEmpty) {
            cellTypeArray.append(type: .Applied, interviewNumber: nil, website: nil)
        }
        let numberOfInterviews = loadedBasic.highestInterviewNumber
        for var i = 1; i <= numberOfInterviews.integerValue; i++ {
            let interviewNumber: Int? = i
            cellTypeArray.append(type: .Interview, interviewNumber: interviewNumber, website: nil)
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTypeArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
        case .Applied:
            return getAppliedCell()
        case .Interview:
            let interviewNumber = cellTypeArray[indexPath.row].interviewNumber!
            return getInterviewCell(interviewNumber)
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(false)
        let website = cellTypeArray[indexPath.row].website
        if website != nil && website != "" {
            performSegueWithIdentifier("showWeb", sender: indexPath)
        }
    }
    
    func getCompanyCell() -> ShowResultCell {
        let company = loadedBasic.company as String
        let title = loadedBasic.title as String
        let salary = loadedBasic.details.salary as NSNumber?
        let dueDate = loadedBasic.details.dueDate as NSDate?
        
        if title.isEmpty && salary == nil && dueDate == nil {
            let cell = tableView.dequeueReusableCellWithIdentifier("showCompanyCell") as ShowResultCell
            
            cell.mainLabel.text = company
            return cell
        } else {
            return getCompanyDetailsCell()
        }
    }
    
    func getCompanyDetailsCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showCompanyWithDetailCell") as ShowResultCell
        
        let company = loadedBasic.company as String
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
        
        cell.mainLabel.text = company
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
    
    func getAppliedCell() -> ShowResultCell {
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
        
        cell.mainLabel.text = "Application Details"
        cell.secondaryLabel!.text = detailsString
        return cell
    }
    
    func getInterviewCell(interviewNumber: Int) -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showStageCell") as ShowResultCell
        
        let interview = loadedBasic.getInterviewFromNumber(interviewNumber)!
        
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
        
        if loadedBasic.highestInterviewNumber.integerValue == 1 {
            cell.mainLabel.text = "Interview Details"
        } else {
            let position = Common.positionStringFromNumber(interviewNumber)!
            cell.mainLabel.text = "\(position) Interview Details"
        }
        cell.secondaryLabel!.text = detailsString
        return cell
    }
    
    @IBAction func stageClicked(sender: UIBarButtonItem) {
        hiddenTextField.becomeFirstResponder()
    }
    
    func stageSelected(newStage: Stage, isPrevious: Bool) {
        self.view.endEditing(false)
        
        if isPrevious {
            goToPreviousStage(newStage)
            return
        }
        
        if newStage == .Applied {
            performSegueWithIdentifier("editApplication", sender: self)
        } else if newStage == .Interview {
            performSegueWithIdentifier("editInterview", sender: self)
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let currentStage = Stage(rawValue: loadedBasic.stage.integerValue)!
            switch newStage {
            case .Decision:
                let decision = NSEntityDescription.insertNewObjectForEntityForName("JobDecision", inManagedObjectContext: managedContext) as JobDecision
                managedContext.insertObject(decision)
                loadedBasic.decision = decision
                decision.basic = loadedBasic
                loadedBasic.details.decisionStarted = true
            case .Offer:
                let offer = NSEntityDescription.insertNewObjectForEntityForName("JobOffer", inManagedObjectContext: managedContext) as JobOffer
                managedContext.insertObject(offer)
                loadedBasic.offer = offer
                offer.basic = loadedBasic
                loadedBasic.details.offerStarted = true
            case .Rejected:
                let rejected = NSEntityDescription.insertNewObjectForEntityForName("JobRejected", inManagedObjectContext: managedContext) as JobRejected
                managedContext.insertObject(rejected)
                loadedBasic.rejected = rejected
                rejected.basic = loadedBasic
            default:
                let i = 0 //remove
            }
            
            loadedBasic.stage = newStage.rawValue
            
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
            
            stageVC.loadedBasic = loadedBasic
            reloadCellTypeArray()
        }
        
        //TODO change to proper stage change
    }
    
    func goToPreviousStage(previousStage: Stage) {
        let currentStage = Stage(rawValue: loadedBasic.stage.integerValue)!
        switch currentStage {
        case .Applied:
            loadedBasic.application = nil
            loadedBasic.details.appliedStarted = false
        case .Interview:
            let numberOfInterviews = loadedBasic.highestInterviewNumber.integerValue
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
            }
        case .Decision:
            loadedBasic.decision = nil
            loadedBasic.details.decisionStarted = false
        case .Offer:
            loadedBasic.offer = nil
            loadedBasic.details.offerStarted = false
        case .Rejected:
            loadedBasic.rejected = nil
        default:
            let i = 0 //remove
        }
        
        loadedBasic.stage = previousStage.rawValue
        
        var error: NSError?
        if !Common.managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
        
        let k = loadedBasic.interviews
        let l = loadedBasic.highestInterviewNumber
        
        stageVC.loadedBasic = loadedBasic
        reloadCellTypeArray()
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
        }
    }
}

//TODO some of the stored data is empty strings and sometimes nil, tidy it up.
