//
//  CollapsableSectionHeaderView.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/30/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

protocol CollapsableSectionHeaderViewDelegate {
    func sectionToggled(section: Int?)
}

class CollapsableSectionHeaderView: UITableViewHeaderFooterView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var arrowLabel: UILabel!
    
    var section: Int?
    var delegate: CollapsableSectionHeaderViewDelegate?
    
    override func awakeFromNib() {
        let tapGesture = UITapGestureRecognizer(target: self, action: "headerSelected")
        self.addGestureRecognizer(tapGesture)
    }
    
    func headerSelected() {
        delegate?.sectionToggled(section)
    }
}