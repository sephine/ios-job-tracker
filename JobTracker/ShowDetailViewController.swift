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

class ShowDetailViewController: UITableViewController {
    
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var salaryLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    var loadedBasic: JobBasic!
    
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
        setBasicDetails()
    }
    
    func setBasicDetails() {
        companyLabel.text = loadedBasic.company
        titleLabel.text = loadedBasic.title
        locationLabel.text = loadedBasic.details.location
        
        let salary = loadedBasic.details.salary
        let formatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.CurrencyStyle
        salaryLabel.text = formatter.stringFromNumber(salary)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destination = segue.destinationViewController as EditDetailViewController
        destination.loadedBasic = loadedBasic
    }
}
