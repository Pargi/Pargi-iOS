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

class MainViewController: PulleyViewController, MapViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Grab all zones and force them down to the map/detail views
        let zones = ApplicationData.currentDatabase.zones
        
        if let mapView = self.primaryContentViewController as? MapViewController {
            mapView.zones = zones
            mapView.delegate = self
        }
    }
    
    // MARK: MapViewControllerDelegate
    
    func mapViewController(_ controller: MapViewController, didUpdateVisibleZones zones: [Zone]) {
        let top = zones[0..<min(zones.count, 5)]
        print("Closest zones \(top.count) => \(top.map({ $0.code }))")
    }
}
