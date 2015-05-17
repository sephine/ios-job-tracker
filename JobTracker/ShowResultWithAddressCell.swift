//
//  ShowInterviewResultCell.swift
//  JobTracker
//
//  Created by Joanne Dyer on 4/2/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

protocol ShowResultWithAddressCellDelegate: class {
    func addressButtonSelectedForOwner(owner: AnyObject)
}

class ShowResultWithAddressCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressButton: UIButton!
    @IBOutlet weak var secondaryLabel: UILabel!
    
    weak var delegate: ShowResultWithAddressCellDelegate!
    var owner: AnyObject!
    
    override func awakeFromNib() {
        addressButton.titleLabel!.lineBreakMode = NSLineBreakMode.ByWordWrapping
        addressButton.addTarget(self, action: "buttonSelected", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    func buttonSelected() {
        delegate.addressButtonSelectedForOwner(owner)
    }
}