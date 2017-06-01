//
//  MainViewController.swift
//  Pargi
//
//  Main view controller, contains both the map as well as the
//  detail VCs and controls the information the two display
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import UIKit
import Pulley

class MainViewController: PulleyViewController, MapViewControllerDelegate, DetailViewControllerDelegate {
    
    fileprivate var mapViewController: MapViewController? {
        get {
            return self.primaryContentViewController as? MapViewController
        }
    }
    
    fileprivate var detailViewController: DetailViewController? {
        get {
            return self.drawerContentViewController as? DetailViewController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Grab all zones and force them down to the map/detail views
        let zones = ApplicationData.currentDatabase.zones
        
        if let mapView = self.mapViewController {
            mapView.zones = zones
            mapView.delegate = self
        }
        
        if let detailView = self.detailViewController {
            detailView.delegate = self
            detailView.previousLicensePlateNumbers = UserData.shared.otherLicensePlateNumbers
            detailView.licensePlateNumber = UserData.shared.licensePlateNumber
        }
    }
    
    // MARK: Segues
    
    @IBAction func unwindToMain(segue: UIStoryboardSegue) {
        
    }
    
    // MARK: MapViewControllerDelegate
    
    func mapViewController(_ controller: MapViewController, didUpdateVisibleZones zones: [Zone]) {
        let bestMatches = Array(zones[0..<min(zones.count, 3)])
        
        if let detailView = self.drawerContentViewController as? DetailViewController {
            detailView.zones = bestMatches
        }
    }
    
    // MARK: DetailViewControllerDelegate
    
    func detailViewController(_ controller: DetailViewController, didSelectZone zone: Zone?) {
        print("Selected zone \(zone)")
    }
    
    func detailViewController(_ controller: DetailViewController, didChangeLicensePlateNumber licensePlate: String?) {
        UserData.shared.licensePlateNumber = licensePlate
        
        if let plate = licensePlate {
            UserData.shared.otherLicensePlateNumbers.insert(plate, at: 0)
            controller.previousLicensePlateNumbers = UserData.shared.otherLicensePlateNumbers
        }
    }
}
