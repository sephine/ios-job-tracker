//
//  MapViewController.swift
//  JobTracker
//
//  Created by Joanne Dyer on 2/20/15.
//  Copyright (c) 2015 Joanne Maynard. All rights reserved.
//

import Foundation

class MapViewController: UIViewController {
    
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var directionsButton: UIButton!
    
    var loadedBasic: JobBasic!
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let exitItem = UIBarButtonItem(title: "X", style: UIBarButtonItemStyle.Plain, target: self, action: "exitSelected")
        navigationBar.rightBarButtonItem = exitItem
        navigationBar.hidesBackButton = true
        
        companyLabel.text = loadedBasic.company
        addressLabel.text = loadedBasic.location.address
        
        //add padding to mapview so that google logo is shown above bottom labels
        mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: 62, right: 0)
        //TODO make sure the bottom value changes if you change the white square height
        
        //disable directions button if google maps not installed
        let googleMapsInstalled = UIApplication.sharedApplication().canOpenURL(NSURL(string: "comgooglemaps://")!)
        if googleMapsInstalled {
            directionsButton.hidden = false
        } else {
            directionsButton.hidden = true
        }
        
        loadLocation()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    //MARK:-
    
    private func loadLocation() {
        let latitude = loadedBasic.location.latitude as Double
        let longitude = loadedBasic.location.longitude as Double
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        let marker = GMSMarker(position: coordinates)
        marker.title = loadedBasic.company
        marker.map = mapView
        
        mapView.camera = GMSCameraPosition(target: coordinates, zoom: 15, bearing: 0, viewingAngle: 0)
    }
    
    private func exitSelected() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    //MARK:- IBActions
    
    @IBAction func mapTypeSegmentClicked(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            mapView.mapType = kGMSTypeNormal
        case 1:
            mapView.mapType = kGMSTypeSatellite
        case 2:
            mapView.mapType = kGMSTypeHybrid
        default:
            mapView.mapType = mapView.mapType
        }
    }
    
    @IBAction func directionsClicked(sender: UIButton) {
        let allowedCharacters = NSCharacterSet.URLQueryAllowedCharacterSet().mutableCopy() as NSMutableCharacterSet
        allowedCharacters.removeCharactersInString("&=?")
        let urlFormAddress = loadedBasic.location.address.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        
        UIApplication.sharedApplication().openURL(NSURL(string:
            "comgooglemaps://?daddr=\(urlFormAddress)&directionsmode=driving")!)
    }
}