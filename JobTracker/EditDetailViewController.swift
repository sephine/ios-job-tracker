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

class EditDetailViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet weak var companyBox: UITextField!
    @IBOutlet weak var positionBox: UITextField!
    @IBOutlet weak var salaryBox: UITextField!
    @IBOutlet weak var locationBox: UITextField!
    
    var loadedBasic: JobBasic?
    var salary: NSNumber?
    let glassdoorPartnerID = "29976"
    let glassdoorPartnerKey = "hfEt8lCsdp9"
    let glassdoorAPIVersion = "1"
    
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
            positionBox.text = basic.title
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
        salary = (newSalary as NSString).doubleValue
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
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func saveClicked(sender: UIBarButtonItem) {
        saveDetails()
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func findCompanyClicked(sender: UIButton) {
        queryGlassdoor(company: companyBox.text, location: locationBox.text)
    }
    
    func queryGlassdoor(#company: String, location: String) {
        let allowedCharacters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as NSMutableCharacterSet
        allowedCharacters.removeCharactersInString("&=?")
        
        let urlFormCompany = company.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        let urlFormLocation = location.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        
        let url = "http://api.glassdoor.com/api/api.htm?t.p=\(glassdoorPartnerID)&t.k=\(glassdoorPartnerKey)&format=json&v=\(glassdoorAPIVersion)&action=employers&q=\(urlFormCompany)&l=\(urlFormLocation)"
        //TODO I have not supplied userIP or userAgent but it is working anyway...
        
        let glassdoorRequestURL = NSURL(string: url)!
        let request = NSURLRequest(URL: glassdoorRequestURL)
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            if error != nil {
                //TODO what to do if the data can't be retrieved.
                assertionFailure("glassdoor API connection failed")
            }
            NSOperationQueue.mainQueue().addOperationWithBlock({
                self.fetchedData(data)
            })
        })
    }
    
    func fetchedData(responseData: NSData) {
        var error: NSError?
        let json = NSJSONSerialization.JSONObjectWithData(responseData, options: nil, error: &error) as NSDictionary
        let response = json["response"] as NSDictionary
        let employers = response["employers"] as NSArray
        NSLog("GlassDoor Data:")
        for employer in employers {
            //let name = employer["name"] as String
            NSLog("\(employer)")
        }
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
        
        basic.title = positionBox.text
        basic.company = companyBox.text
        details.salary = salary!
        details.location = locationBox.text
        
        loadedBasic = basic
        
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save \(error), \(error?.userInfo)")
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as ShowDetailViewController
        destination.loadedBasic = loadedBasic
    }
}

//TODO check for empty text boxes
