//
//  ViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/4/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import UIKit
import CoreData

class JobListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fetchRequest = NSFetchRequest(entityName: "JobBasic")
        let sectionSortDescriptor = NSSortDescriptor(key: "stage", ascending: true)
        let companySortDescriptor = NSSortDescriptor(key: "company", ascending: true, selector: "caseInsensitiveCompare:")
        let sortDescriptors = [sectionSortDescriptor, companySortDescriptor]
        fetchRequest.sortDescriptors = sortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Common.managedContext, sectionNameKeyPath: "stage", cacheName: "Root")
        fetchedResultsController.delegate = self
        
        var error: NSError?
        if !fetchedResultsController.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
        
        checkForPassedInterviewsAndUpdateStages()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //check if any of the stages have moved from PreInteview to PostInterview since last opened.
    func checkForPassedInterviewsAndUpdateStages() {
        let sections = fetchedResultsController.sections!
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
        return fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        let stageNumber = sectionInfo.name!.toInt()!
        let stage = Stage(rawValue: stageNumber)!
        return stage.title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section] as NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("jobListResultCell") as JobListResultCell
        configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            let job = fetchedResultsController.objectAtIndexPath(indexPath) as JobBasic
            deleteJob(job)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showJob", sender: indexPath)
    }
    
    func configureCell(cell: JobListResultCell, atIndexPath indexPath: NSIndexPath) {
        let job = fetchedResultsController.objectAtIndexPath(indexPath) as JobBasic
        cell.companyLabel.text = job.company
        cell.positionLabel.text = job.title
        
        let stage = Stage(rawValue: job.stage.integerValue)!
        var dateText: String
        var displayRedText = false
        switch stage {
        case .Potential:
            let dueDate = job.details.dueDate
            if dueDate != nil {
                let dueDateString = Common.standardDateFormatter.stringFromDate(dueDate!)
                dateText = "Deadline \(dueDateString)"
                
                if isDateWithinAWeekOfToday(date: dueDate!) {
                    displayRedText = true
                }
            } else {
                dateText = "No Deadline"
            }
        case .Applied:
            let dateApplied = job.application!.dateSent
            let dateAppliedString = Common.standardDateFormatter.stringFromDate(dateApplied)
            dateText = "Applied \(dateAppliedString)"
        case .PreInterview:
            var nextInterviewDate: NSDate?
            for interview in job.orderedInterviews {
                if !interview.completed {
                    nextInterviewDate = interview.starts
                    break
                }
            }
            let nextInterviewDateString = Common.standardDateFormatter.stringFromDate(nextInterviewDate!)
            dateText = "Scheduled \(nextInterviewDateString)"
            
            if isDateWithinAWeekOfToday(date: nextInterviewDate!) {
                displayRedText = true
            }
        case .PostInterview:
            let lastInterviewDate = job.orderedInterviews.last!.ends
            let lastInterviewDateString = Common.standardDateFormatter.stringFromDate(lastInterviewDate)
            dateText = "Completed \(lastInterviewDateString)"
        case .Offer:
            let dateReceived = job.offer!.dateReceived
            let dateReceivedString = Common.standardDateFormatter.stringFromDate(dateReceived)
            dateText = "Received \(dateReceivedString)"
        case .Rejected:
            let dateRejected = job.rejected!.dateRejected
            let dateRejectedString = Common.standardDateFormatter.stringFromDate(dateRejected)
            dateText = "Rejected \(dateRejectedString)"
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
        
        //use the start of the dates so that the time of day does not affect the number of days difference.
        let startOfDate = calendar.startOfDayForDate(date)
        let startOfToday = calendar.startOfDayForDate(today)
        
        let components = calendar.components(.CalendarUnitDay, fromDate: startOfToday, toDate: startOfDate, options: nil)
        let daysDifference = components.day
        
        if daysDifference >= 0 && daysDifference < 7 {
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
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        let tableView = self.tableView
        switch type {
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        case .Delete:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
        case .Update:
            configureCell(tableView.cellForRowAtIndexPath(indexPath!)! as JobListResultCell, atIndexPath: indexPath!)
        case .Move:
            tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            let indexSet = NSIndexSet(index: sectionIndex)
            tableView.insertSections(indexSet, withRowAnimation: .Automatic)
        case .Delete:
            let indexSet = NSIndexSet(index: sectionIndex)
            self.tableView.deleteSections(indexSet, withRowAnimation: .Automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showJob" {
            let indexPath = sender as NSIndexPath
            //let stage = nonEmptyStages[indexPath.section]
            //let basic = (jobs[stage]!)[indexPath.row] as JobBasic
            let job = fetchedResultsController.objectAtIndexPath(indexPath) as JobBasic
            let showJobDestination = segue.destinationViewController as ShowDetailViewController
            showJobDestination.loadedBasic = job
        }
    }
}

//TODO order by dates not by company names??