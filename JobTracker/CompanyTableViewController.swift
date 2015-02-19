//
//  CompanyTableViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/12/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit

protocol CompanySelectionDelegate {
    func companySelected(company: String, website: String, glassdoorLink: String)
}

class CompanyTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    @IBOutlet weak var search: UISearchBar!
    var delegate: CompanySelectionDelegate!
    
    var companies: [AnyObject]?
    var connectionError = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Find Company"
        //tableView.registerClass(CompanyManualCell.self, forCellReuseIdentifier: "companyManualCell")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.text.isEmpty {
            companies = nil
            connectionError = false
            tableView.reloadData()
        } else {
            GlassdoorCompanySearch().queryGlassdoor(company: searchBar.text, callbackFunction: updateWithCompanyResults)
        }
    }
    
    func updateWithCompanyResults(success: Bool, companyResults: [AnyObject]?) {
        companies = companyResults
        connectionError = !success
        tableView.reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if search.text.isEmpty {
            return nil
        }
        
        if section == 0 {
            return "Manual Entry"
        }
        return "Search Results"
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 44
        }
        return 78
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if search.text.isEmpty {
                return 0
            }
            return 1
        }
        
        if connectionError {
            // Display a message when a connection error has occurred.
            let messageLabel = UILabel(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            messageLabel.text = "Unable to retrieve data at this time.\nPlease try again later."
            messageLabel.textColor = UIColor.blackColor()
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = NSTextAlignment.Center
            //messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20]
            messageLabel.sizeToFit()
            self.tableView.backgroundView = messageLabel
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            return 0
        }
        self.tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        self.tableView.backgroundView = nil
        if companies == nil {
            return 0
        }
        return companies!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("companyManualCell", forIndexPath: indexPath) as UITableViewCell
            cell.textLabel!.text = search.text
            return cell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("companyResultCell", forIndexPath: indexPath) as CompanyResultCell
        let company = companies![indexPath.row] as NSDictionary
        let squareLogo = company["squareLogo"] as String
        if squareLogo != "" {
            let url = NSURL(string: squareLogo)
            if url != nil {
                cell.logo.sd_setImageWithURL(url!)
            }
        }
        cell.company.text = (company["name"] as String)
        cell.website.text = (company["website"] as String)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
            let cell = tableView.cellForRowAtIndexPath(indexPath)
            let company = cell?.textLabel!.text
            delegate.companySelected(company!, website: "", glassdoorLink: "")
        } else {
            let company = companies![indexPath.row] as NSDictionary
            let companyName = (company["name"] as String)
            let website = (company["website"] as String)
            let glassdoorID = company["id"] as NSNumber
            let glassdoorIDString = glassdoorID.description
            let glassdoorLink = "http://www.glassdoor.com/Job/Square-Jobs-E\(glassdoorIDString).htm"
            delegate.companySelected(companyName, website: website, glassdoorLink: glassdoorLink)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
}