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
    
    var location: JobLocation!
    var locationTitle: String!
    
    //MARK:- UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        assert(!location.address.isEmpty, "The map view must be given a non-empty location")
        
        let exitItem = UIBarButtonItem(title: "X", style: UIBarButtonItemStyle.Plain, target: self, action: "exitSelected")
        navigationBar.rightBarButtonItem = exitItem
        navigationBar.hidesBackButton = true
        
        companyLabel.text = locationTitle
        addressLabel.text = location.address
        
        //add padding to mapview so that google logo is shown above bottom labels
        mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: 62, right: 0)
        //TODO make sure the bottom value changes if you change the white square height
        
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
        let latitude = location.latitude as Double?
        let longitude = location.longitude as Double?
        if latitude == nil || longitude == nil {
            AddressCoordinateSearch.getPlacemark(location.address, fetchedPlacemark)
        } else {
        let coordinates = CLLocationCoordinate2D(latitude: latitude!, longitude: longitude!)
        
        let marker = GMSMarker(position: coordinates)
        marker.title = locationTitle
        marker.map = mapView
        
        mapView.camera = GMSCameraPosition(target: coordinates, zoom: 15, bearing: 0, viewingAngle: 0)
        }
    }
    
    func exitSelected() {
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
        let urlFormAddress = location.address.stringByAddingPercentEncodingWithAllowedCharacters(allowedCharacters)!
        
        //open in apple maps if user doesn't have google maps
        var startOfURL = "comgooglemaps://"
        let googleMapsInstalled = UIApplication.sharedApplication().canOpenURL(NSURL(string: startOfURL)!)
        if !googleMapsInstalled {
            startOfURL = "http://maps.apple.com/"
        }
        
        UIApplication.sharedApplication().openURL(NSURL(string:
            "\(startOfURL)?daddr=\(urlFormAddress)")!)//TODO remove &directionsmode=driving
    }
    
    //MARK:- Core Data Changers
    
    func fetchedPlacemark(#address: String, placemark: CLPlacemark?) {
        if placemark == nil {
            let alert = UIAlertView(title: "Cannot find location", message: nil, delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        } else {
            location.latitude = placemark!.location.coordinate.latitude
            location.longitude = placemark!.location.coordinate.longitude
            var error: NSError?
            if !Common.managedContext.save(&error) {
                println("Could not save \(error), \(error?.userInfo)")
            }
            loadLocation()
        }
    }
}