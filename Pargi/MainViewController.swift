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
import MessageUI
import Pulley

class MainViewController: PulleyViewController, MapViewControllerDelegate, DetailViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    private var selectedZone: Zone? = nil
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == "searchZonesList", let target = (segue.destination as? UINavigationController)?.topViewController as? SearchViewController {
            target.zones = ApplicationData.currentDatabase.zones
        }
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
        self.selectedZone = zone
    }
    
    func detailViewController(_ controller: DetailViewController, didChangeLicensePlateNumber licensePlate: String?) {
        UserData.shared.licensePlateNumber = licensePlate
        
        if let plate = licensePlate {
            UserData.shared.otherLicensePlateNumbers.insert(plate, at: 0)
            controller.previousLicensePlateNumbers = UserData.shared.otherLicensePlateNumbers
        }
    }
    
    func detailViewControllerDidPressParkButton(_ controller: DetailViewController) {
        guard let zone = self.selectedZone, let licensePlate = UserData.shared.licensePlateNumber else {
            return
        }
        
        guard MFMessageComposeViewController.canSendText() else {
            // Show an alert, we can't send SMS
            let alert = UIAlertController(title: "UI.NoSMSCapability".localized(withComment: "SMSi saatmine ebaõnnestus"), message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(withComment: "OK"), style: .default))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let composeController = MFMessageComposeViewController(licensePlate: licensePlate, zone: zone)
        composeController.messageComposeDelegate = self
        self.present(composeController, animated: true, completion: nil)
    }
    
    // MARK: MFMessageComposeViewControllerDelegate
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {        
        // Dismiss the composer
        self.presentedViewController?.dismiss(animated: true, completion: nil)

        switch result {
        case .sent:
            // Kick off parking tracking
            var userData = UserData.shared
            userData.isParked = true
            userData.parkedAt = Date()
            userData.currentParkedZone = self.selectedZone
            
            // TODO: Transfer to the parked view
            print("TODO: Move to parked view")
        case .failed:
            // Failed, we should show an error
            // Show an alert, we can't send SMS
            let alert = UIAlertController(title: "UI.SMSFailed".localized(withComment: "SMSi saatmine ebaõnnestus"), message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK".localized(withComment: "OK"), style: .default))
            self.present(alert, animated: true, completion: nil)
        case .cancelled:
            break
        }
    }
}
