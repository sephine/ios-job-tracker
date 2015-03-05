//
//  EditApplicationViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/22/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class EditApplicationViewController: UITableViewController {
    
    @IBOutlet weak var dateSentBox: UITextField!
    @IBOutlet weak var notesView: UITextView!
    
    var loadedBasic: JobBasic!
    let datePickerView = UIDatePicker()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Application"
        
        datePickerView.datePickerMode = UIDatePickerMode.Date
        datePickerView.addTarget(self, action: "updateDate", forControlEvents: UIControlEvents.ValueChanged)
        dateSentBox.inputView = datePickerView
        
        if let application = loadedBasic.application {
            title = "Edit Application"
            notesView.text = application.notes
            
            let date = application.dateSent as NSDate?
            if date == nil {
                dateSentBox.text = ""
            } else {
                let dateFormatter = NSDateFormatter()
                dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
                dateSentBox.text = dateFormatter.stringFromDate(date!)
                datePickerView.date = date!
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //show toolbar only on edit application (not create new)
        if loadedBasic.application != nil {
            self.navigationController?.toolbarHidden = false
        } else {
            self.navigationController?.toolbarHidden = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.toolbarHidden = true
    }
    
    @IBAction func updateDate() {
        let date = datePickerView.date
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
        dateSentBox.text = dateFormatter.stringFromDate(date)
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        saveDetails()
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func deleteClicked(sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(cancelAction)
        let deleteAction = UIAlertAction(title: "Delete Application", style: .Destructive, handler: { (action) in self.deleteApplication()
        })
        alertController.addAction(deleteAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    func saveDetails() {
        let managedContext = Common.managedContext
        var application: JobApplication
        if loadedBasic.application != nil {
            application = loadedBasic.application!
        } else {
            application = NSEntityDescription.insertNewObjectForEntityForName("JobApplication", inManagedObjectContext: managedContext) as JobApplication
            managedContext.insertObject(application)
            loadedBasic.details.appliedStarted = true
            loadedBasic.stage = Stage.Applied.rawValue
            loadedBasic.application = application
            application.basic = loadedBasic
        }
        
        application.notes = notesView.text
        
        if dateSentBox.text!.isEmpty {
            application.dateSent = nil
        } else {
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            application.dateSent = dateFormatter.dateFromString(dateSentBox.text!)
        }
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    func deleteApplication() {
        if let application = loadedBasic.application {
            loadedBasic.application = nil
            loadedBasic.details.appliedStarted = false
            if loadedBasic.stage == Stage.Applied.rawValue {
                loadedBasic.stage = Stage.Potential.rawValue
            }

            var error: NSError?
            if !Common.managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
}

//TODO check for empty text boxes

