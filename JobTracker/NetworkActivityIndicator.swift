//
//  NetworkActivityIndicator.swift
//  JobTracker
//
//  Created by Joanne Dyer on 4/2/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

//not threadsafe just for use in main thread after asynchronous calls have finished.
struct NetworkActivityIndicator {
    static var numberOfActivities = 0
    
    static func startActivity() {
        if numberOfActivities == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        }
        numberOfActivities++
    }
    
    static func stopActivity() {
        if numberOfActivities != 0 {
            numberOfActivities--
        }
        if numberOfActivities == 0 {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        }
    }
    
    static func resetActivities() {
        numberOfActivities = 0
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
}