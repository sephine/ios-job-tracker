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
    case Company, CompanyDetails, Location, CompanyWebsite, JobListing, GlassdoorLink, Notes, Application
}

class ShowDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StageSelectionDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var hiddenTextField: UITextField!
    
    var stageVC: StageViewController!
    //var stageView: UIView!
    var loadedBasic: JobBasic!
    var cellTypeArray = [(ShowCellType, String?)]()
    
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
        cellTypeArray = [(ShowCellType, String?)]()
        cellTypeArray.append((.CompanyDetails, nil))
        cellTypeArray.append((.Location, nil))
        cellTypeArray.append((.Notes, nil))
        cellTypeArray.append((.Application, nil))
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
        refreshPage()
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
        let cellType = cellTypeArray[indexPath.row].0
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
        case .Application:
            return getApplicationCell()
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.view.endEditing(false)
        let website = cellTypeArray[indexPath.row].1
        if website != nil && website != "" {
            performSegueWithIdentifier("showWeb", sender: indexPath)
        }
    }
    
    func refreshPage() {
        let stage = Stage(rawValue: loadedBasic.stage.integerValue)!
        title = stage.title
        
        cellTypeArray = [(ShowCellType, String?)]()
        cellTypeArray.append((.Company, nil))
        
        let address = loadedBasic.location.address
        if !address.isEmpty {
            cellTypeArray.append((.Location, nil))
        }
        
        let website = loadedBasic.details.website
        if !website.isEmpty {
            cellTypeArray.append((.CompanyWebsite, website))
        }
        
        let listing = loadedBasic.details.jobListing
        if !listing.isEmpty {
            cellTypeArray.append((.JobListing, listing))
        }
        
        let glassdoor = loadedBasic.details.glassdoorLink
        if !glassdoor.isEmpty {
            cellTypeArray.append((.GlassdoorLink, glassdoor))
        }
        
        let dateSent = loadedBasic.application?.dateSent
        if dateSent != nil {
            cellTypeArray.append((.Application, nil))
        }
        
        let notes = loadedBasic.details.notes
        let applicationNotes = loadedBasic.application?.notes
        if !notes.isEmpty || (applicationNotes != nil && !applicationNotes!.isEmpty) {
            cellTypeArray.append((.Notes, nil))
        }
        
        tableView.reloadData()
        
        //adding an empty footer ensures that the table view doesn't show empty rows
        tableView.tableFooterView = UIView(frame: CGRectZero)
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
            let salaryFormatter = NSNumberFormatter()
            salaryFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            salaryString = salaryFormatter.stringFromNumber(salary!)
        }
        
        var dueDateString: String?
        if dueDate != nil {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            dueDateString = dateFormatter.stringFromDate(dueDate!)
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
        
        var detailsArray = [String]()
        let potentialNotes = loadedBasic.details.notes
        if !potentialNotes.isEmpty {
            detailsArray.append("\(potentialNotes)")
        }
        
        let applicationNotes = loadedBasic.application?.notes
        if applicationNotes != nil && !applicationNotes!.isEmpty {
            detailsArray.append("\(Stage.Applied.title):\n\(applicationNotes!)")
        }
        
        let detailsString = join("\n\n", detailsArray)
        
        cell.secondaryLabel!.text = detailsString
        return cell
    }
    
    func getApplicationCell() -> ShowResultCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showApplicationCell") as ShowResultCell
        let dateSent = loadedBasic.application?.dateSent
        var dateSentString: String?
        if dateSent != nil {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            dateSentString = dateFormatter.stringFromDate(dateSent!)
        }
        
        var detailsArray = [String]()
        if dateSentString != nil {
            detailsArray.append("Sent: \(dateSentString!)")
        }
        let detailsString = join("\n", detailsArray)
        
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
        } else {
            let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
            let managedContext = appDelegate.managedObjectContext!
            
            let currentStage = Stage(rawValue: loadedBasic.stage.integerValue)!
            switch newStage {
            case .Interview:
                let interview = NSEntityDescription.insertNewObjectForEntityForName("JobInterview", inManagedObjectContext: managedContext) as JobInterview
                managedContext.insertObject(interview)
                
                if loadedBasic.interviews == nil {
                    loadedBasic.interviews = NSSet()
                }
                loadedBasic.interviews!.setByAddingObject(interview)
                interview.basic = loadedBasic
                loadedBasic.details.interviewStarted = true
                
                if currentStage == .Interview {
                    let oldInterviewNumber = loadedBasic.highestInterviewNumber!.integerValue
                    loadedBasic.highestInterviewNumber = oldInterviewNumber + 1
                    interview.interviewNumber = oldInterviewNumber + 1
                } else {
                    loadedBasic.highestInterviewNumber = 1
                    interview.interviewNumber = 1
                }
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
            refreshPage()
        }
        
        //TODO change to proper stage change
    }
    
    func goToPreviousStage(previousStage: Stage) {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        let currentStage = Stage(rawValue: loadedBasic.stage.integerValue)!
        switch currentStage {
        case .Applied:
            loadedBasic.application = nil
            loadedBasic.details.appliedStarted = false
        case .Interview:
            let numberOfInterviews = loadedBasic.highestInterviewNumber!.integerValue
            if numberOfInterviews >= 2 {
                let interviewSet = loadedBasic.interviews!.mutableCopy() as NSMutableSet
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
                let i = loadedBasic.interviews
                let j = loadedBasic.highestInterviewNumber
            } else {
                loadedBasic.interviews = nil
                loadedBasic.highestInterviewNumber = nil
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
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
        
        let k = loadedBasic.interviews
        let l = loadedBasic.highestInterviewNumber
        
        stageVC.loadedBasic = loadedBasic
        refreshPage()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showWeb" {
            let indexPath = sender as NSIndexPath
            let website = cellTypeArray[indexPath.row].1
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
        }
    }
    
    /*func setUpConstraints() {
        
        let stageView = stageVC.view
        //stageView.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        stageVC.view.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        
        let heightConstraint = NSLayoutConstraint(item: stageView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.NotAnAttribute, multiplier: 1.0, constant: 198.0)//160
        stageView.addConstraint(heightConstraint)
        /*let leadingConstraint = NSLayoutConstraint(item: stageView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0)
        view.addConstraint(leadingConstraint)
        let trailingConstraint = NSLayoutConstraint(item: stageView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0)
        view.addConstraint(trailingConstraint)
        let bottomConstraint = NSLayoutConstraint(item: stageView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: bottomLayoutGuide, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0)
        view.addConstraint(bottomConstraint)*/
        
    }*/
}

//TODO some of the stored data is empty strings and sometimes nil, tidy it up.
