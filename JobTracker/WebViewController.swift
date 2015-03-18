//
//  WebViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/18/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class WebViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet weak var containedWebView: UIWebView!
    @IBOutlet weak var navigationBar: UINavigationItem!
    
    var website: String!
    var backItem: UIBarButtonItem!
    var forwardItem: UIBarButtonItem!
    var firstLoad = true
    var haveTriedGoogling = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //stops an inset being added when the app is brought back from being in the background.
        automaticallyAdjustsScrollViewInsets = false
        
        var url: NSURL?
        if !website.hasPrefix("http://") {
            url = NSURL(string: "http://\(website)")
        } else {
            url = NSURL(string: website)
        }
        
        let request = NSURLRequest(URL: url!)
        containedWebView.loadRequest(request)
        
        backItem = UIBarButtonItem(title: "<", style: UIBarButtonItemStyle.Plain, target: self, action: "backSelected")
        forwardItem = UIBarButtonItem(title: ">", style: UIBarButtonItemStyle.Plain, target: self, action: "forwardSelected")
        let exitItem = UIBarButtonItem(title: "X", style: UIBarButtonItemStyle.Plain, target: self, action: "exitSelected")
        navigationBar.leftBarButtonItems = nil
        navigationBar.rightBarButtonItem = exitItem
        navigationBar.hidesBackButton = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(15)]
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName: UIFont.boldSystemFontOfSize(17)]
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        if firstLoad {
            navigationBar.title = "Loading..."
            firstLoad = false
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        navigationBar.title = webView.stringByEvaluatingJavaScriptFromString("document.title")
        if navigationBar.leftBarButtonItem == nil &&
            (containedWebView.canGoBack || containedWebView.canGoForward) {
            navigationBar.leftBarButtonItems = [backItem, forwardItem]
        }
        
        if containedWebView.canGoBack {
            backItem.enabled = true
        } else {
            backItem.enabled = false
        }
        
        if containedWebView.canGoForward {
            forwardItem.enabled = true
        } else {
            forwardItem.enabled = false
        }
        
        let i = webView.scrollView.contentSize
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        if !haveTriedGoogling {
            let googleSearchString = "http://google.com/search?q=\(website)"
            let url = NSURL(string: googleSearchString)
            let request = NSURLRequest(URL: url!)
            containedWebView.loadRequest(request)
            haveTriedGoogling = true
        } else {
            navigationBar.title = "Failed To Load Page"
            //TODO do something with error?
        }
    }
    
    func backSelected() {
        if containedWebView.canGoBack {
            containedWebView.goBack()
        }
    }
    
    func forwardSelected() {
        if containedWebView.canGoForward {
            containedWebView.goForward()
        }
    }
    
    func exitSelected() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    //TODO change images
}