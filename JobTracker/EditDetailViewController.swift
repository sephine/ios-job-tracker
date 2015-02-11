//
//  JobDetailViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/5/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class EditDetailViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var titleBox: UITextField!
    @IBOutlet weak var companyBox: UITextField!
    @IBOutlet weak var salaryBox: UITextField!
    @IBOutlet weak var locationBox: UITextField!
    
    var loadedBasic: JobBasic?
    var salary: NSNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Job Detail"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let basic = loadedBasic {
            titleBox.text = basic.title
            companyBox.text = basic.company
            locationBox.text = basic.details.location
            
            salary = basic.details.salary
            let formatter = NSNumberFormatter()
            formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            salaryBox.text = formatter.stringFromNumber(salary!)
        }
    }
    
    //only called by salary text field (the rest don't have this class set as delegate.
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let newSalary = salaryBox.text + string
        let expression = "^\\d+\\.?\\d{0,2}$"
        let regex = NSRegularExpression(pattern: expression, options: nil, error: nil)
        let numberOfMatches = regex?.numberOfMatchesInString(newSalary, options: nil, range: NSMakeRange(0, countElements(newSalary)))
        if numberOfMatches == 0 {
            return false
        }
        return true
    }
    
    //only called by salary text field (the rest don't have this class set as delegate.
    func textFieldDidBeginEditing(textField: UITextField) {
        if salary != nil {
            salaryBox.text = salary!.stringValue
        }
    }
    
    //only called by salary text field (the rest don't have this class set as delegate.
    func textFieldDidEndEditing(textField: UITextField) {
        if salaryBox.text == "" {
            salary = nil
            return
        }
        salary = (salaryBox.text as NSString).doubleValue
            
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        salaryBox.text = formatter.stringFromNumber(salary!)
    }
    
    @IBAction func CancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func SaveClicked(sender: UIBarButtonItem) {
        saveDetails()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func saveDetails() {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        
        var basic: JobBasic
        var details: JobDetail
        if loadedBasic != nil {
            basic = loadedBasic!
            details = basic.details
        } else {
            basic = NSEntityDescription.insertNewObjectForEntityForName("JobBasic", inManagedObjectContext: managedContext) as JobBasic
            details = NSEntityDescription.insertNewObjectForEntityForName("JobDetail", inManagedObjectContext: managedContext) as JobDetail
            managedContext.insertObject(basic)
            managedContext.insertObject(details)
            basic.stage = Stage.Potential.rawValue
            basic.details = details
            details.basic = basic
        }
        
        basic.title = titleBox.text
        basic.company = companyBox.text
        details.salary = salary!
        details.location = locationBox.text
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
}

//TODO check for empty text boxes


/*var salaryString = salaryBox.text
let stringLength = countElements(salaryString)
if stringLength > 0 {
// add .00 on the end if necessary
let expression = "^\\d+\\.?\\d{0,2}$"
let regex = NSRegularExpression(pattern: expression, options: nil, error: nil)
if regex?.numberOfMatchesInString(salaryString + ".00", options: nil, range: NSMakeRange(0, countElements(salaryString + ".00"))) == 1 {
salaryBox.text = salaryString + ".00"
} else if regex?.numberOfMatchesInString(salaryString + "00", options: nil, range: NSMakeRange(0, countElements(salaryString + "00"))) == 1 {
salaryBox.text = salaryString + "00"
} else if regex?.numberOfMatchesInString(salaryString + "0", options: nil, range: NSMakeRange(0, countElements(salaryString + "0"))) == 1 {
salaryBox.text = salaryString + "0"
}*/