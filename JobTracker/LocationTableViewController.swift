//
//  LocationTableViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/14/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit

protocol LocationSelectionDelegate {
    func locationSelected(location: String)
}

class LocationTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {
    
    @IBOutlet weak var search: UISearchBar!
    var delegate: LocationSelectionDelegate!
    
    var locations: [AnyObject]?
    var connectionError = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Find Locations"
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
            locations = nil
            connectionError = false
            tableView.reloadData()
        } else {
            GoogleLocationSearch().queryGoogle(location: searchBar.text, callbackFunction: updateWithLocationResults)
        }
    }
    
    func updateWithLocationResults(success: Bool, locationResults: [AnyObject]?) {
        locations = locationResults
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
        if locations == nil {
            return 0
        }
        return locations!.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("locationResultCell", forIndexPath: indexPath) as UITableViewCell
        if indexPath.section == 0 {
            cell.textLabel!.text = search.text
            return cell
        }
        let location = locations![indexPath.row] as NSDictionary
        let locationDescription = location["description"] as String
        cell.textLabel!.text = locationDescription
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)
        let location = cell?.textLabel!.text
        delegate.locationSelected(location!)
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    //TODO think about whether these automatically unwrapped optionals are safe!
}