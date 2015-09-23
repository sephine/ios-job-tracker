//
//  AddressCoordinateSearch.swift
//  JobTracker
//
//  Created by Joanne Dyer on 4/2/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class AddressCoordinateSearch {
    
    class func getPlacemark(address: String, callbackFunction: (String, CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        NetworkActivityIndicator.startActivity()
        geocoder.geocodeAddressString(address, completionHandler: {(results, error) -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if error != nil {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    NetworkActivityIndicator.stopActivity()
                    callbackFunction(address, nil)
                    //TODO what to do if the data can't be retrieved.
                })
            } else {
                let placemarks = results as? [CLPlacemark]
                var bestPlacemark: CLPlacemark? = nil
                if placemarks != nil && placemarks!.count > 0 {
                    bestPlacemark = placemarks![0]
                }
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    NetworkActivityIndicator.stopActivity()
                    callbackFunction(address, bestPlacemark)
                })
            }
        })
    }
}