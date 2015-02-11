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
    case Potential = 0, Applied, Interview, ReceivedOffer, Rejected
    
    static let allValues = [Potential, Applied, Interview, ReceivedOffer, Rejected]
    
    var title: String {
        switch self {
        case .Potential:
            return "Potential Jobs"
        case .Applied:
            return "Application Sent"
        case .Interview:
            return "Interview Arranged"
        case .ReceivedOffer:
            return "Offer Received"
        case .Rejected:
            return "Rejected"
        }
    }
}

class JobListViewController: UITableViewController {

    //@IBOutlet weak var jobTableView: UITableView!
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
            var jobBasics = [Stage: [JobBasic]]()
            for stage in Stage.allValues {
                jobBasics[stage] = [JobBasic]()
            }
            for result in results {
                let basic = result as JobBasic
                let stage = Stage(rawValue: basic.stage.integerValue)!
                jobBasics[stage]!.append(basic)
            }
            jobs = jobBasics
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return Stage.allValues.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let stage = Stage(rawValue: section)!
        return stage.title
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let stage = Stage(rawValue: section)!
        return jobs[stage]!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let section = indexPath.section//
        let row = indexPath.row//
        
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell") as UITableViewCell
        let stage = Stage(rawValue: indexPath.section)!
        let job = (jobs[stage]!)[indexPath.row]
        let company = job.company//
        let title = job.title//
        cell.textLabel!.text = job.company
        cell.detailTextLabel!.text = job.title
        return cell
    }
}

