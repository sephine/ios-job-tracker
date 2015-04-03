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

class JobListViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchDisplayDelegate, CollapsableSectionHeaderViewDelegate {
    
    @IBOutlet weak var sortControl: UISegmentedControl!
    
    //there are two FRCs for when the standard tableview is sorted by stage or date and a third one for the seperate search tableview. Only one will be used to display data at a time.
    private var stageFRC: NSFetchedResultsController!
    private var dateFRC: NSFetchedResultsController!
    private var searchFRC: NSFetchedResultsController!
    
    private var stageSectionsExpanded: [Bool]!
    private var dateSectionsExpanded: [Bool]!
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //accessing the shared instance ensures that the class is initiated and so observes saves.
        CoreDataObserver.sharedInstance
        
        setUpArraysOfExpandedSections()
        
        setUpStageFetchedResultsController()
        setUpDateFetchedResultsController()
        setUpSearchFetchedResultsController()
        
        self.tableView.rowHeight = 60.0
        self.searchDisplayController!.searchResultsTableView.rowHeight = 60.0
        
        //adding an empty footer ensures that the table view doesn't show empty rows
        self.searchDisplayController!.searchResultsTableView.tableFooterView = UIView(frame: CGRectZero)
        
        let sectionHeaderNib = UINib(nibName: "CollapsableSectionHeaderView", bundle: nil)
        tableView.registerNib(sectionHeaderNib, forHeaderFooterViewReuseIdentifier: "collapsableSectionHeaderView")
        
        tableView.reloadData()
        checkForPassedInterviewsAndUpdateStages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showJob" {
            let job = sender as JobBasic
            let showJobDestination = segue.destinationViewController as ShowDetailViewController
            showJobDestination.loadedBasic = job
        }
    }
    
    //MARK:-
    
    private func setUpArraysOfExpandedSections() {
        //initially all sections are expanded
        stageSectionsExpanded = []
        for stage in Stage.allValues {
            stageSectionsExpanded.append(true)
        }
        dateSectionsExpanded = [true, true]
    }
    
    private func setUpStageFetchedResultsController() {
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
    
    private func setUpDateFetchedResultsController() {
        let fetchRequest = NSFetchRequest(entityName: "JobBasic")
        let sectionSortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        let companySortDescriptor = NSSortDescriptor(key: "company", ascending: true, selector: "caseInsensitiveCompare:")
        
        let sortDescriptors = [sectionSortDescriptor, companySortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        
        dateFRC = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Common.managedContext, sectionNameKeyPath: "inFuture", cacheName: "inFuture")
        dateFRC.delegate = self
        
        var error: NSError?
        if !dateFRC.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }
    
    private func setUpSearchFetchedResultsController() {
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
    
    //MARK:- IBActions
    
    @IBAction func sectionTypeChanged(sender: UISegmentedControl) {
        self.tableView.reloadData()
    }
    
    //MARK:- FRC Management
    //based on the table view being shown and the sort selected different FRCs must be used. Only updates for the currently in use FRC should be made.
    
    private func frcForTableView(tableView: UITableView) -> NSFetchedResultsController {
        if tableView == self.searchDisplayController!.searchResultsTableView {
            return searchFRC
        } else if sortControl.selectedSegmentIndex == SortType.Stage.rawValue {
            return stageFRC
        }
        return dateFRC
    }
    
    private func tableViewForFRC(controller: NSFetchedResultsController) -> UITableView {
        if controller == searchFRC {
            return self.searchDisplayController!.searchResultsTableView
        }
        return self.tableView
    }
    
    private func shouldUpdateTableViewWithChangesFromController(controller: NSFetchedResultsController) -> Bool {
        if searchDisplayController!.active {
            return controller == searchFRC
        } else if sortControl.selectedSegmentIndex == SortType.Stage.rawValue {
            return controller == stageFRC
        }
        return controller == dateFRC
    }
    
    //MARK:- Collapsable Sections (
    
    private func isSectionExpanded(section: Int, controller: NSFetchedResultsController) -> Bool {
        if controller == searchFRC {
            return true
        } else if controller == stageFRC {
            return stageSectionsExpanded[section]
        }
        return dateSectionsExpanded[section]
    }
    
    //MARK:- CollapsableSectionHeaderViewDelegate
    
    func sectionToggled(section: Int?) {
        if section != nil {
            //won't be called for search as it shows no sections.
            if sortControl.selectedSegmentIndex == SortType.Stage.rawValue {
                stageSectionsExpanded[section!] = !stageSectionsExpanded[section!]
            } else {
                dateSectionsExpanded[section!] = !dateSectionsExpanded[section!]
            }
            
            tableView.beginUpdates()
            let indexSet = NSIndexSet(index: section!)
            tableView.reloadSections(indexSet, withRowAnimation: .Automatic)
            tableView.endUpdates()
        }
    }
    
    //MARK:- UISearchDisplayDelegate
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        filterResultsForSearchText(searchString)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController, didHideSearchResultsTableView tableView: UITableView) {
        //while the search table view is active the main table view will not have been getting updates and will need to be reloaded
        self.tableView.reloadData()
    }
    
    //MARK:-
    
    private func filterResultsForSearchText(searchText: String) {
        searchFRC.fetchRequest.predicate = NSPredicate(format: "company BEGINSWITH[cd] %@", searchText)
        
        var error: NSError?
        if !searchFRC.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }
    
    //MARK:- UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let currentFRC = frcForTableView(tableView)
        return currentFRC.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let currentFRC = frcForTableView(tableView)
        let sectionExpanded = isSectionExpanded(section, controller: currentFRC)
        if sectionExpanded {
            let sectionInfo = currentFRC.sections![section] as NSFetchedResultsSectionInfo
            return sectionInfo.numberOfObjects
        }
        return 0
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
    
    //MARK:-
    
    private func configureCell(tableView: UITableView, cell: JobListResultCell, atIndexPath indexPath: NSIndexPath) {
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
            let dateString = NSDateFormatter().stringFromDifferenceInDateToToday(date: job.date)
            
            //var dateString = Common.standardDateFormatter.stringFromDate(job.date)
            
            switch stage {
            case .Potential:
                dateText = "Application deadline \(dateString)"
                if isDateWithinAWeekOfToday(date: job.date) {
                    displayRedText = true
                }
            case .Applied:
                dateText = "Applied \(dateString)"
            case .PreInterview:
                dateText = "Interview scheduled \(dateString)"
                if isDateWithinAWeekOfToday(date: job.date) {
                    displayRedText = true
                }
            case .PostInterview:
                dateText = "Interview completed \(dateString)"
            case .Offer:
                dateText = "Received offer \(dateString)"
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
    
    private func isDateWithinAWeekOfToday(#date: NSDate) -> Bool {
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

    //MARK:- UITableViewDelegate
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let currentFRC = frcForTableView(tableView)
        if currentFRC == searchFRC {
            return super.tableView(tableView, viewForHeaderInSection: section)
        }
            
        let headerView = self.tableView.dequeueReusableHeaderFooterViewWithIdentifier("collapsableSectionHeaderView") as CollapsableSectionHeaderView
        headerView.section = section
        headerView.delegate = self
        headerView.titleLabel.text = getHeaderTitle(currentFRC: currentFRC, section: section).uppercaseString
        
        let sectionExpanded = isSectionExpanded(section, controller: currentFRC)
        if sectionExpanded {
            headerView.arrowLabel.text = "\u{25BC}"//black arrow pointing down
        } else {
            headerView.arrowLabel.text = "\u{25B6}\u{FE0E}"//black arrow pointing right
        }
        
        return headerView
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let currentFRC = frcForTableView(tableView)
        if currentFRC == searchFRC {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
        if section == 0 {
            return 55.5
        }
        return 38.0
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentFRC = frcForTableView(tableView)
        let job = currentFRC.objectAtIndexPath(indexPath) as JobBasic
        performSegueWithIdentifier("showJob", sender: job)
    }
    
    //MARK:-
    
    private func getHeaderTitle(#currentFRC: NSFetchedResultsController, section: Int) -> String {
        let sectionInfo = currentFRC.sections![section] as NSFetchedResultsSectionInfo
        if currentFRC == stageFRC {
            let sectionNumber = sectionInfo.name!.toInt()!
            let stage = Stage(rawValue: sectionNumber)!
            return stage.title
        } else if currentFRC == dateFRC {
            let sectionNumber = sectionInfo.name!.toInt()!
            if sectionNumber == 0 {
                return "Past"
            }
            return "Future"
        }
        return ""
    }
    
    //MARK:- NSFetchedResultsControllerDelegate
    
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
                if isSectionExpanded(newIndexPath!.section, controller: controller) {
                    connectedTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
                }
            case .Delete:
                if isSectionExpanded(indexPath!.section, controller: controller) {
                    connectedTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                }
            case .Update:
                if isSectionExpanded(indexPath!.section, controller: controller) {
                    configureCell(connectedTableView, cell: connectedTableView.cellForRowAtIndexPath(indexPath!)! as JobListResultCell, atIndexPath: indexPath!)
                }
            case .Move:
                if isSectionExpanded(indexPath!.section, controller: controller) {
                    connectedTableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                }
                if isSectionExpanded(newIndexPath!.section, controller: controller) {
                    connectedTableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
                }
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
    
    //MARK:- Core Data Changers
    
    //check if any of the stages have moved from PreInteview to PostInterview since last opened. Also check for changes in dates of interviews.
    private func checkForPassedInterviewsAndUpdateStages() {
        let sections = stageFRC.sections!
        for section in sections {
            let section = section as NSFetchedResultsSectionInfo
            let stageNumber = section.name!.toInt()!
            let stage = Stage(rawValue: stageNumber)!
            
            if stage == .PreInterview || stage == .PostInterview {
                for basic in section.objects {
                    let basic = basic as JobBasic
                    for interview in basic.interviews {
                        let interview = interview as JobInterview
                        EventManager.sharedInstance.syncInterviewWithCalendarEvent(interview: interview)
                    }
                }
            }
        }
    }
    
    private func deleteJob(job: JobBasic) {
        Common.managedContext.deleteObject(job)
        var error: NSError?
        if !Common.managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
}

//TODO can you add two identical jobs?