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
        let sortDescriptors = [NSSortDescriptor(key: "company", ascending: true, selector: "caseInsensitiveCompare:")]
        fetchRequest.sortDescriptors = sortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: Common.managedContext, sectionNameKeyPath: "stage", cacheName: "Root")
        fetchedResultsController.delegate = self
        
        var error: NSError?
        if !fetchedResultsController.performFetch(&error) {
            NSLog("Could not fetch results \(error), \(error?.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
            deleteJob(indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showJob", sender: indexPath)
    }
    
    func configureCell(cell: JobListResultCell, atIndexPath indexPath: NSIndexPath) {
        let job = fetchedResultsController.objectAtIndexPath(indexPath) as JobBasic
        cell.companyLabel.text = job.company
        cell.positionLabel.text = job.title
    }
    
    func deleteJob(indexPath: NSIndexPath) {
        let job = fetchedResultsController.objectAtIndexPath(indexPath) as JobBasic
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