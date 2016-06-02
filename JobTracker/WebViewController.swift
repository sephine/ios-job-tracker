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
    
    private var backItem: UIBarButtonItem!
    private var forwardItem: UIBarButtonItem!
    private var firstLoad = true
    
    //MARK:- UIViewController
    
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
        
        backItem = UIBarButtonItem(title: "\u{3008}", style: UIBarButtonItemStyle.Plain, target: self, action: "backSelected")
        forwardItem = UIBarButtonItem(title: "\u{3009}", style: UIBarButtonItemStyle.Plain, target: self, action: "forwardSelected")
        let exitItem = UIBarButtonItem(title: "x", style: UIBarButtonItemStyle.Plain, target: self, action: "exitSelected")
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
    
    //MARK:-
    
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
        //might be closed before all the finish/fail loads are called. There shouldn't be any network activity going on after this view is closed.
        NetworkActivityIndicator.resetActivities()
    }
    
    //MARK:- UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView) {
        NetworkActivityIndicator.startActivity()
        if firstLoad {
            navigationBar.title = "Loading..."
            firstLoad = false
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        NetworkActivityIndicator.stopActivity()
        firstLoad = false
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
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        NetworkActivityIndicator.stopActivity()
        if error!.code == NSURLErrorCancelled {
            return
        }
        
        if error!.code == NSURLErrorCannotFindHost {
            let googleSearchString = "http://google.com/search?q=\(website)"
            let url = NSURL(string: googleSearchString)
            let request = NSURLRequest(URL: url!)
            containedWebView.loadRequest(request)
            return
        }
        
        navigationBar.title = "Failed To Load Page"
        let alert = UIAlertView(title: "Failed To Load Page", message: "Please check your internet connection.", delegate: nil, cancelButtonTitle: "OK")
        alert.show()
    }
    
    //TODO: not working properly when part of the page (not the main part) fails to load, also when you press back it crashes
    
    //TODO: change images
}