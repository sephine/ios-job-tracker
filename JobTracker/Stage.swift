//
//  Stage.swift
//  JobTracker
//
//  Created by Joanne Dyer on 3/31/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

enum Stage: Int {
    case Potential = 0, Applied, PreInterview, PostInterview, Offer, Rejected
    
    static let allValues = [Potential, Applied, PreInterview, PostInterview, Offer, Rejected]
    
    var title: String {
        switch self {
        case .Potential:
            return "Potential Job"
        case .Applied:
            return "Application Sent"
        case .PreInterview:
            return "Interview Scheduled"
        case .PostInterview:
            return "Interview Completed"
        case .Offer:
            return "Offer Received"
        case .Rejected:
            return "Rejected"
        }
    }
}

