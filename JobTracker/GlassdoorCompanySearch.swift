//
//  GlassdoorCompanySearch.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/12/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class GlassdoorCompanySearch {
    
    func queryGlassdoor(company company: String, callbackFunction: (Bool, [AnyObject]?) -> Void) {
        let allowedCharacters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as! NSMutableCharacterSet
        allowedCharacters.removeCharactersInString("&=?")
        
        let urlFormCompany = company.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        
        let url = "http://api.glassdoor.com/api/api.htm?t.p=\(Keys.glassdoorPartnerID)&t.k=\(Keys.glassdoorPartnerKey)&format=json&v=\(Keys.glassdoorAPIVersion)&action=employers&q=\(urlFormCompany)"
        
        let glassdoorRequestURL = NSURL(string: url)!
        let request = NSURLRequest(URL: glassdoorRequestURL)
        let queue = NSOperationQueue()
        
        NetworkActivityIndicator.startActivity()
        NSURLConnection.sendAsynchronousRequest(request, queue: queue, completionHandler: { (response: NSURLResponse?, data: NSData?, error: NSError?) in
            if error != nil {
                //TODO: what to do if the data can't be retrieved. Should state a problem with the internet connection for example.
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    NetworkActivityIndicator.stopActivity()
                    callbackFunction(false, nil)
                })
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock({
                    NetworkActivityIndicator.stopActivity()
                    self.fetchedData(data!, callbackFunction: callbackFunction)
                })
            }
        })
    }
    
    func fetchedData(responseData: NSData, callbackFunction: (Bool, [AnyObject]?) -> Void) {
        let json = try? NSJSONSerialization.JSONObjectWithData(responseData, options: []) as! NSDictionary
        if json == nil || (json!["success"] as! Bool) != true {
            callbackFunction(false, nil)
        } else {
            let response = json!["response"] as! NSDictionary
            let companies = response["employers"] as! [AnyObject]
            callbackFunction(true, companies)
        }
    }

    //TODO: make keys secret, move them into seperate file?
    //TODO: check the async bit is working correctly
}