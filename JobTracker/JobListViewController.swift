//
//  ViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/4/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData

enum SortType: Int {
    case Stage = 0, Date
}

class JobListViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchDisplayDelegate {
    
    @IBOutlet weak var sortControl: UISegmentedControl!
    
    //there are two FRCs for when the standard tableview is sorted by stage or date and a third one for the seperate search tableview. Only one will be used to display data at a time.
    var stageFRC: NSFetchedResultsController!
    var dateFRC: NSFetchedResultsController!
    var searchFRC: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //accessing the shared instance ensures that the class is initiated and so observes saves.
        CoreDataObserver.sharedInstance
        
        setUpStageFetchedResultsController()
        setUpDateFetchedResultsController()
        setUpSearchFetchedResultsController()
        checkForPassedInterviewsAndUpdateStages()
        
        self.tableView.rowHeight = 60.0
        self.searchDisplayController!.searchResultsTableView.rowHeight = 60.0
        
        //adding an empty footer ensures that the table view doesn't show empty rows
        self.searchDisplayController!.searchResultsTableView.tableFooterView = UIView(frame: CGRectZero)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setUpStageFetchedResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "JobBasic")
        let sectionSortDescriptor = NSSortDescriptor(key: "stage", ascending: true)
        let companySortDescriptor = NSSortDescriptor(key: "company", ascending: true, selector: "caseInsensitiveCompare:")
        
        let sortDescriptors = [sectionSortDescriptor, companySortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        stageFRC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Common.managedContext, sectionNameKeyPath: "stage", cacheName: "company")
        stageFRC.delegate = self
        
        var error: NSError?
        if !stageFRC.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }
    
    func setUpDateFetchedResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "JobBasic")
        let sectionSortDescriptor = NSSortDescriptor(key: "date", ascending: false)
        let companySortDescriptor = NSSortDescriptor(key: "company", ascending: true, selector: "caseInsensitiveCompare:")
        
        let sortDescriptors = [sectionSortDescriptor, companySortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        dateFRC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Common.managedContext, sectionNameKeyPath: "inPast", cacheName: "inPast")
        dateFRC.delegate = self
        
        var error: NSError?
        if !dateFRC.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }
    
    func setUpSearchFetchedResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "JobBasic")
        let companySortDescriptor = NSSortDescriptor(key: "company", ascending: true, selector: "caseInsensitiveCompare:")
        let sortDescriptors = [companySortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        searchFRC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Common.managedContext, sectionNameKeyPath: nil, cacheName: nil)
        searchFRC.delegate = self
        
        var error: NSError?
        if !searchFRC.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }
    
    @IBAction func sectionTypeChanged(sender: UISegmentedControl) {
        self.tableView.reloadData()
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        filterResultsForSearchText(searchString)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, didHideSearchResultsTableView tableView: UITableView) {
        //while the search table view is active the main table view will not have been getting updates and will need to be reloaded
        self.tableView.reloadData()
    }
    
    func frcForTableView(tableView: UITableView) -> NSFetchedResultsController {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return searchFRC
        } else if sortControl.selectedSegmentIndex == SortType.Stage.rawValue {
            return stageFRC
        }
        return dateFRC
    }
    
    func tableViewForFRC(controller: NSFetchedResultsController) -> UITableView {
        if controller == searchFRC {
            return self.searchDisplayController!.searchResultsTableView
        }
        return self.tableView
    }
    
    //we only want updates to a tableview to be made when they come from the controller that is currently controlling the data displayed.
    func shouldUpdateTableViewWithChangesFromController(controller: NSFetchedResultsController) -> Bool {
        if searchDisplayController!.active {
            return controller == searchFRC
        } else if sortControl.selectedSegmentIndex == SortType.Stage.rawValue {
            return controller == stageFRC
        }
        return controller == dateFRC
    }
    
    func filterResultsForSearchText(searchText: String) {
        searchFRC.fetchRequest.predicate = NSPredicate(format: "company BEGINSWITH[cd] %@", searchText)

        var error: NSError?
        if !searchFRC.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }
    
    //check if any of the stages have moved from PreInteview to PostInterview since last opened.
    func checkForPassedInterviewsAndUpdateStages() {
        let sections = stageFRC.sections!
        for section in sections {
            let section = section as NSFetchedResultsSectionInfo
            let stageNumber = section.name!.toInt()!
            let stage = Stage(rawValue: stageNumber)!
            
            if stage == .PreInterview {
                for basic in section.objects {
                    let basic = basic as JobBasic
                    var allComplete = true
                    for interview in basic.interviews {
                        if !(interview as JobInterview).completed {
                            allComplete = false
                            break
                        }
                    }
                    if allComplete {
                        basic.stage = Stage.PostInterview.rawValue
                    }
                }
                
                var error: NSError?
                if !Common.managedContext.save(&error) {
                    println("Could not save \(error), \(error?.userInfo)")
                }
                return
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let currentFRC = frcForTableView(tableView)
        return currentFRC.sections!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let currentFRC = frcForTableView(tableView)
        let sectionInfo = currentFRC.sections![section] as NSFetchedResultsSectionInfo
        if currentFRC == stageFRC {
            let sectionNumber = sectionInfo.name!.toInt()!
            let stage = Stage(rawValue: sectionNumber)!
            return stage.title
        } else if currentFRC == dateFRC {
            let sectionNumber = sectionInfo.name!.toInt()!
            if sectionNumber == 0 {
                return "Future"
            }
            return "Past"
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentFRC = frcForTableView(tableView)
        let sectionInfo = currentFRC.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = self.tableView.dequeueReusableCellWithIdentifier("jobListResultCell") as JobListResultCell
        configureCell(tableView, cell: cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let currentFRC = frcForTableView(tableView)
            let job = currentFRC.objectAtIndexPath(indexPath) as JobBasic
            deleteJob(job)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentFRC = frcForTableView(tableView)
        let job = currentFRC.objectAtIndexPath(indexPath) as JobBasic
        performSegueWithIdentifier("showJob", sender: job)
    }
    
    func configureCell(tableView: UITableView, cell: JobListResultCell, atIndexPath indexPath: NSIndexPath) {
        let currentFRC = frcForTableView(tableView)
        let job = currentFRC.objectAtIndexPath(indexPath) as JobBasic

        cell.companyLabel.text = job.company
        cell.positionLabel.text = job.title
        
        let stage = Stage(rawValue: job.stage.integerValue)!
        var dateText: String
        var displayRedText = false
        if stage == .Potential && job.details.dueDate == nil {
            //in this case job.date holds a date in the far future for the purposes of date sorting in the table view, but text should show no deadline.
            dateText = "No Deadline"
        } else {
            var dateString = Common.standardDateFormatter.stringFromDate(job.date)
            switch stage {
            case .Potential:
                dateText = "Deadline \(dateString)"
                if isDateWithinAWeekOfToday(date: job.date) {
                    displayRedText = true
                }
            case .Applied:
                dateText = "Applied \(dateString)"
            case .PreInterview:
                dateText = "Scheduled \(dateString)"
                if isDateWithinAWeekOfToday(date: job.date) {
                    displayRedText = true
                }
            case .PostInterview:
                dateText = "Completed \(dateString)"
            case .Offer:
                dateText = "Received \(dateString)"
            case .Rejected:
                dateText = "Rejected \(dateString)"
            }
        }
        
        cell.dateLabel.text = dateText
        if displayRedText {
            cell.dateLabel.textColor = UIColor.redColor()
        } else {
            cell.dateLabel.textColor = UIColor.darkGrayColor()
        }
        
        //TODO red makes it seem like the date is in the past! consider orange
        //TODO could get a library that displays dates like 5 days time, a month ago etc
    }
    
    func isDateWithinAWeekOfToday(#date: NSDate) -> Bool {
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        
        //use the start of the dates so that the time of day does not affect the number of days difference for the upper limit. The warning should appear at the start of the day but should end as soon as the event has passed.
        let startOfDate = calendar.startOfDayForDate(date)
        let startOfToday = calendar.startOfDayForDate(today)
        
        let components = calendar.components(.CalendarUnitDay, fromDate: startOfToday, toDate: startOfDate, options: nil)
        let daysDifference = components.day
        
        if daysDifference < 7 && date.timeIntervalSinceNow > 0.0 {
            return true
        }
        return false
    }
    
    func deleteJob(job: JobBasic) {
        Common.managedContext.deleteObject(job)
        var error: NSError?
        if !Common.managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        if shouldUpdateTableViewWithChangesFromController(controller) {
            let connectedTableView = tableViewForFRC(controller)
            connectedTableView.beginUpdates()
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        if shouldUpdateTableViewWithChangesFromController(controller) {
            let connectedTableView = tableViewForFRC(controller)
            switch type {
            case .Insert:
                connectedTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            case .Delete:
                connectedTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            case .Update:
                configureCell(connectedTableView, cell: connectedTableView.cellForRowAtIndexPath(indexPath!)! as JobListResultCell, atIndexPath: indexPath!)
            case .Move:
                connectedTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                connectedTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        if shouldUpdateTableViewWithChangesFromController(controller) {
            let connectedTableView = tableViewForFRC(controller)
            switch type {
            case .Insert:
                let indexSet = NSIndexSet(index: sectionIndex)
                connectedTableView.insertSections(indexSet, withRowAnimation: .Automatic)
            case .Delete:
                let indexSet = NSIndexSet(index: sectionIndex)
                connectedTableView.deleteSections(indexSet, withRowAnimation: .Automatic)
            default:
                break
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if shouldUpdateTableViewWithChangesFromController(controller) {
            let connectedTableView = tableViewForFRC(controller)
            connectedTableView.endUpdates()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showJob" {
            let job = sender as JobBasic
            let showJobDestination = segue.destinationViewController as ShowDetailViewController
            showJobDestination.loadedBasic = job
        }
    }
}

//TODO can you add two identical jobs?