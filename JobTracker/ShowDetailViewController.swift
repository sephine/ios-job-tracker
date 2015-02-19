//
//  ShowDetailsViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/10/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit

enum ShowCellType {
    case Company, CompanyWebsite, JobListing, GlassdoorLink
}

class ShowDetailViewController: UITableViewController {
    
    var loadedBasic: JobBasic!
    var cellTypeArray = [(ShowCellType, String?)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Job Detail"
        
        cellTypeArray.append((.Company, nil))
        
        let website = loadedBasic.details.website
        if !website.isEmpty {
            cellTypeArray.append((.CompanyWebsite, website))
        }
        
        let listing = loadedBasic.details.jobListing
        if !listing.isEmpty {
            cellTypeArray.append((.JobListing, listing))
        }
        
        let glassdoor = loadedBasic.details.glassdoorLink
        if !glassdoor.isEmpty {
            cellTypeArray.append((.GlassdoorLink, glassdoor))
        }
        
        //cellTypeArray.append((.CompanyWebsite, loadedBasic.details.website))
        
        
        tableView.estimatedRowHeight = 69.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    /*func setBasicDetails() {
        companyLabel.text = loadedBasic.company
        companyDetailLabel.text = loadedBasic.title
        //titleLabel.text = loadedBasic.title
        //locationLabel.text = loadedBasic.details.location
        
        let salary = loadedBasic.details.salary as NSNumber?
        if salary != nil {
            let salaryFormatter = NSNumberFormatter()
            salaryFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
            let salaryString = salaryFormatter.stringFromNumber(salary!)! as String
            companyDetailLabel.text = companyDetailLabel.text! + "\n\(salaryString)"
            companyDetailLabel.numberOfLines = 2
            //salaryLabel.text = salaryFormatter.stringFromNumber(salary!)
        }
    }*/
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTypeArray.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellType = cellTypeArray[indexPath.row].0
        switch cellType {
        case .Company:
            return getCompanyCell()
        case .CompanyWebsite:
            return getBasicCell("Company Website")
        case .JobListing:
            return getBasicCell("Job Listing")
        case .GlassdoorLink:
            return getGlassdoorCell()
        }
    }
    
    /*override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let cell = getCompanyCell()
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        let size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        return size.height + 1.0
    }*/
    
    func getCompanyCell() -> ShowCompanyCell {
        var cell: ShowCompanyCell
        let salary = loadedBasic.details.salary as NSNumber?
        if loadedBasic.title.isEmpty && salary == nil {
            cell = tableView.dequeueReusableCellWithIdentifier("showCompanyCell") as ShowCompanyCell
            cell.companyLabel.text = loadedBasic.company
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier("showCompanyWithDetailCell") as ShowCompanyCell
            
            var salaryString: String?
            if salary != nil {
                let salaryFormatter = NSNumberFormatter()
                salaryFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
                salaryString = salaryFormatter.stringFromNumber(salary!)!
            }
            
            var detailsString: String
            if !loadedBasic.title.isEmpty {
                detailsString = loadedBasic.title
                if salaryString != nil {
                    detailsString = detailsString + "\n\(salaryString!)"
                }
            } else {
                detailsString = salaryString!
            }
            
            cell.companyLabel.text = loadedBasic.company
            cell.detailsLabel!.text = detailsString
        }
        
        return cell
    }
    
    func getBasicCell(text: String) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showBasicCell") as UITableViewCell
        cell.textLabel!.text = text
        return cell
    }
    
    func getGlassdoorCell() -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("showGlassdoorCell") as UITableViewCell
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as EditDetailViewController
        destination.loadedBasic = loadedBasic
    }
    
    /*let boldFont = UIFont.boldSystemFontOfSize(17)
    let standardFont = UIFont.systemFontOfSize(17)
    var detailsString = loadedBasic.company
    if !loadedBasic.title.isEmpty {
    detailsString = detailsString + "\n\(loadedBasic.title)"
    }
    let salary = loadedBasic.details.salary as NSNumber?
    if salary != nil {
    let salaryFormatter = NSNumberFormatter()
    salaryFormatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
    let salaryString = salaryFormatter.stringFromNumber(salary!)! as String
    detailsString = detailsString + "\n\(salaryString)"
    }
    let companyLength = countElements(loadedBasic.company)
    let fullLength = countElements(detailsString)
    
    let attributedString = NSMutableAttributedString(string: detailsString)
    attributedString.addAttribute(NSFontAttributeName, value: boldFont, range: NSMakeRange(0, fullLength))
    attributedString.addAttribute(NSFontAttributeName, value: standardFont, range: NSMakeRange(companyLength, fullLength - companyLength))
    cell.textLabel!.attributedText = attributedString*/
}
