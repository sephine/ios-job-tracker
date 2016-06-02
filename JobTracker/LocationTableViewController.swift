//
//  LocationTableViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/14/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit

protocol LocationSelectionDelegate: class {
    func locationSelected(address: String)
    func coordinatesCalculated(address address: String, coordinates: CLLocationCoordinate2D)
}

class LocationTableViewController: UITableViewController, UISearchBarDelegate {
    
    @IBOutlet weak var search: UISearchBar!
    weak var delegate: LocationSelectionDelegate!
    
    private var locations: [AnyObject]?
    private var connectionError = false
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Find Locations"
        
        //adding an empty footer ensures that the table view doesn't show empty rows
        self.tableView.tableFooterView = UIView(frame: CGRectZero)
        
        search.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK:- UISearchBarDelegate
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        if searchBar.text!.isEmpty {
            locations = nil
            connectionError = false
            tableView.reloadData()
        } else {
            GoogleLocationSearch().queryGoogle(address: searchBar.text!, callbackFunction: updateWithLocationResults)
        }
    }
    
    //MARK:-
    
    private func updateWithLocationResults(success: Bool, locationResults: [AnyObject]?) {
        locations = locationResults
        connectionError = !success
        tableView.reloadData()
    }
    
    //MARK:- UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if search.text!.isEmpty {
            return nil
        }
        
        if section == 0 {
            return "Manual Entry"
        }
        return "Search Results"
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if search.text!.isEmpty {
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
        if locations == nil || locations!.count == 0 {
            return 0
        }
        return locations!.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //show google attribution on last row
        if indexPath.section == 1 && indexPath.row == locations!.count {
            let attributionCell = tableView.dequeueReusableCellWithIdentifier("googleAttributionCell") as! AttributionCell
            attributionCell.logo.image = UIImage(named: "powered-by-google-on-white.png")
            attributionCell.logo.contentMode = .Center
            return attributionCell
        }
        
        let cell = tableView.dequeueReusableCellWithIdentifier("locationResultCell", forIndexPath: indexPath) as! LocationResultCell
        if indexPath.section == 0 {
            cell.locationLabel.text = search.text
            return cell
        }
        let location = locations![indexPath.row] as! NSDictionary
        let address = location["description"] as! String
        cell.locationLabel.text = address
        return cell
    }
    
    //MARK:- UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 || indexPath.row < locations!.count {
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! LocationResultCell
            let address = cell.locationLabel.text!
            delegate.locationSelected(address)
            AddressCoordinateSearch.getPlacemark(address, callbackFunction: fetchedPlacemark)
            navigationController?.popViewControllerAnimated(true)
        }
    }
    
    //MARK:-
    
    func fetchedPlacemark(address address: String, placemark: CLPlacemark?) {
        if placemark != nil {
            delegate.coordinatesCalculated(address: address, coordinates: placemark!.location!.coordinate)
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func cancelClicked(sender: UIBarButtonItem) {
        navigationController?.popViewControllerAnimated(true)
    }
    //TODO: think about whether these automatically unwrapped optionals are safe!
    
    //TODO: can maybe have autocomplete back on for location search
    
    //TODO: powered by google on search results
    //TODO: attribution in About page
}