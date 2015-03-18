//
//  EditRejectViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/6/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class EditRejectViewController: UITableViewController {
    
    @IBOutlet weak var notesView: UITextView!
    
    var loadedBasic: JobBasic!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let rejected = loadedBasic.rejected {
            notesView.text = rejected.notes
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        saveDetails()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func saveDetails() {
        let managedContext = Common.managedContext
        var rejected: JobRejected
        if loadedBasic.rejected != nil {
            rejected = loadedBasic.rejected!
        } else {
            rejected = NSEntityDescription.insertNewObjectForEntityForName("JobRejected", inManagedObjectContext: managedContext) as JobRejected
            managedContext.insertObject(rejected)
            loadedBasic.rejected = rejected
            rejected.basic = loadedBasic
            rejected.dateRejected = NSDate()
        }
        
        rejected.notes = notesView.text
        loadedBasic.updateStageToFurthestStageReached()
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
}

