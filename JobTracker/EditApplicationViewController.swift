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
    
    private let datePickerView = UIDatePicker()
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Application"
        
        datePickerView.datePickerMode = UIDatePickerMode.Date
        datePickerView.addTarget(self, action: "updateDate", forControlEvents: UIControlEvents.ValueChanged)
        dateSentBox.inputView = datePickerView
        
        if let application = loadedBasic.application {
            title = "Edit Application"
            notesView.text = application.notes
            
            let savedDate = application.dateSent as NSDate
            dateSentBox.text = Common.standardDateFormatter.stringFromDate(savedDate)
            datePickerView.date = savedDate
        } else {
            let today = datePickerView.date
            dateSentBox.text = Common.standardDateFormatter.stringFromDate(today)
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.destinationViewController is ShowDetailViewController {
            let destination = segue.destinationViewController as ShowDetailViewController
            destination.loadedBasic = loadedBasic
        }
    }
    
    //MARK:-
    
    func updateDate() {
        let date = datePickerView.date
        dateSentBox.text = Common.standardDateFormatter.stringFromDate(date)
    }

    //MARK:- UITableViewDelegate
    
    //sets it up so that wherever in the cell they select the textbox starts editing.
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.row {
        case 0:
            dateSentBox.becomeFirstResponder()
        case 1:
            //TODO remove if you remove sent to cell.
            break
        case 2:
            notesView.becomeFirstResponder()
        default:
            break
        }
    }
    
    //MARK:- IBActions
    
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
    
    //MARK:- Core Data Changers
    
    private func saveDetails() {
        let managedContext = Common.managedContext
        var application: JobApplication
        if loadedBasic.application != nil {
            application = loadedBasic.application!
        } else {
            application = NSEntityDescription.insertNewObjectForEntityForName("JobApplication", inManagedObjectContext: managedContext) as JobApplication
            managedContext.insertObject(application)
            loadedBasic.application = application
            application.basic = loadedBasic
        }
        
        application.notes = notesView.text
        application.dateSent = Common.standardDateFormatter.dateFromString(dateSentBox.text!)!
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    private func deleteApplication() {
        if let application = loadedBasic.application {
            loadedBasic.application = nil
            
            var error: NSError?
            if !Common.managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
            navigationController?.popViewControllerAnimated(true)
        }
    }
}


