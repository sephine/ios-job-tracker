//
//  ViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/4/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import UIKit
import CoreData

enum Stage: Int {
    case Potential = 0, Applied, Interview, Decision, Offer, Rejected
    
    static let allValues = [Potential, Applied, Interview, Decision, Offer, Rejected]
    
    var title: String {
        switch self {
        case .Potential:
            return "Potential Job"
        case .Applied:
            return "Application Sent"
        case .Interview:
            return "Interview Arranged"
        case .Decision:
            return "Awaiting Decision"
        case .Offer:
            return "Offer Received"
        case .Rejected:
            return "Rejected"
        }
    }
}

class JobListViewController: UITableViewController {

    //@IBOutlet weak var jobTableView: UITableView!
    var nonEmptyStages = [Stage]()
    var jobs = [Stage: [JobBasic]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Job List"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "JobBasic")
        let sortDescriptors = [NSSortDescriptor(key: "company", ascending: true)]
        fetchRequest.sortDescriptors = sortDescriptors
        
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error)
        
        if let results = fetchedResults {
            nonEmptyStages = [Stage]()
            jobs = [Stage: [JobBasic]]()
            for result in results {
                let basic = result as JobBasic
                let stage = Stage(rawValue: basic.stage.integerValue)!
                if jobs.indexForKey(stage) == nil {
                    jobs[stage] = [basic]
                } else {
                    jobs[stage]!.append(basic)
                }
            }
            //create an ordered list of the stages that need to be shown
            for stage in Stage.allValues {
                if jobs.indexForKey(stage) != nil {
                    nonEmptyStages.append(stage)
                }
            }

        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return jobs.keys.array.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nonEmptyStages[section].title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stage = nonEmptyStages[section]
        return jobs[stage]!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listCell") as UITableViewCell
        let stage = nonEmptyStages[indexPath.section]
        let job = (jobs[stage]!)[indexPath.row]
        cell.textLabel!.text = job.company
        cell.detailTextLabel!.text = job.title
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("showJob", sender: indexPath)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showJob" {
            let indexPath = sender as NSIndexPath
            let stage = nonEmptyStages[indexPath.section]
            let basic = (jobs[stage]!)[indexPath.row] as JobBasic
            let showJobDestination = segue.destinationViewController as ShowDetailViewController
            showJobDestination.loadedBasic = basic
        }
    }
}