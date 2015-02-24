//
//  GoogleLocationSearch.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/13/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class GoogleLocationSearch {
    
    let googleServerAPIKey = "AIzaSyDxGHbRI_3_291MW8UV-9eu5h4hIEQLpJg"
    
    func queryGoogle(#address: String, callbackFunction: (Bool, [AnyObject]?) -> Void) {
        let allowedCharacters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as NSMutableCharacterSet
        allowedCharacters.removeCharactersInString("&=?")
        
        let urlFormAddress = address.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        
        let url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(urlFormAddress)&key=\(googleServerAPIKey)"
        
        let googleRequestURL = NSURL(string: url)!
        let request = NSURLRequest(URL: googleRequestURL)
        let queue = NSOperationQueue()
        
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            if error != nil {
                //TODO what to do if the data can't be retrieved.
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    callbackFunction(false, nil)
                })
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    self.fetchedData(data, callbackFunction)
                })
            }
        })
    }
    
    func fetchedData(responseData: NSData, callbackFunction: (Bool, [AnyObject]?) -> Void) {
        var error: NSError?
        let json = NSJSONSerialization.JSONObjectWithData(responseData, options: nil, error: &error) as NSDictionary
        let status = json["status"] as String
        if status != "OK" && status != "ZERO_RESULTS" {
            callbackFunction(false, nil)
        }
        let places = json["predictions"] as [AnyObject]
        callbackFunction(true, places)
    }
}
