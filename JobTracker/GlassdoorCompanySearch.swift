//
//  GlassdoorCompanySearch.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/12/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class GlassdoorCompanySearch {
    
    let glassdoorPartnerID = "29976"
    let glassdoorPartnerKey = "hfEt8lCsdp9"
    let glassdoorAPIVersion = "1"
    
    func queryGlassdoor(#company: String, callbackFunction: (Bool, [AnyObject]?) -> Void) {
        let allowedCharacters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as NSMutableCharacterSet
        allowedCharacters.removeCharactersInString("&=?")
        
        let urlFormCompany = company.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        
        let url = "http://api.glassdoor.com/api/api.htm?t.p=\(glassdoorPartnerID)&t.k=\(glassdoorPartnerKey)&format=json&v=\(glassdoorAPIVersion)&action=employers&q=\(urlFormCompany)"
        
        let glassdoorRequestURL = NSURL(string: url)!
        let request = NSURLRequest(URL: glassdoorRequestURL)
        let queue = NSOperationQueue()
        
        NetworkActivityIndicator.startActivity()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse!, data: NSData!, error: NSError!) in
            if error != nil {
                //TODO: what to do if the data can't be retrieved. Should state a problem with the internet connection for example.
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    NetworkActivityIndicator.stopActivity()
                    callbackFunction(false, nil)
                })
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    NetworkActivityIndicator.stopActivity()
                    self.fetchedData(data, callbackFunction)
                })
            }
        })
    }
    
    func fetchedData(responseData: NSData, callbackFunction: (Bool, [AnyObject]?) -> Void) {
        var error: NSError?
        let json = NSJSONSerialization.JSONObjectWithData(responseData, options: nil, error: &error) as NSDictionary
        if (json["success"] as Bool) == false {
            callbackFunction(false, nil)
        }
        let response = json["response"] as NSDictionary
        let companies = response["employers"] as [AnyObject]
        callbackFunction(true, companies)
    }

    //TODO: make keys secred, move them into seperate file?
    //TODO: check the async bit is working correctly
}