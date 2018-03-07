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
import MapKit

class MainViewController: PulleyViewController, MapViewControllerDelegate, DetailViewControllerDelegate, ParkedViewControllerDelegate {
    private var selectedZone: Zone? = nil
    
    enum ParkedState {
        case driving
        case parked
    }
    
    // Updating parking info
    var timer: Timer?
    fileprivate let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.zeroFormattingBehavior = [.dropLeading, .dropTrailing]
        formatter.unitsStyle = .abbreviated
        
        return formatter
    }()
    fileprivate let costFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.currencyCode = "EUR"

        return formatter
    }()
    
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
    
    fileprivate var parkedViewController: ParkedViewController? {
        get {
            return self.drawerContentViewController as? ParkedViewController
        }
    }
    
    fileprivate var state: ParkedState! {
        didSet {
            guard let storyboard = self.storyboard else {
                return
            }
            
            guard let state = self.state else {
                return
            }
            
            let controller: UIViewController
            
            switch state {
                case .driving:
                    controller = storyboard.instantiateViewController(withIdentifier: "DrivingView")
                case .parked:
                    controller = storyboard.instantiateViewController(withIdentifier: "ParkedView")
            }
            
            self.setDrawerContentViewController(controller: controller)
            self.handleDrawerContentsChanged()
            
            self.mapViewController?.isUserInteractionEnabled = state == .driving
            self.timer?.fire()
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
        
        // Hide search button unless specified by env
        #if !ENABLE_SEARCH
            self.navigationItem.leftBarButtonItem = nil
        #endif
        
        // Observe changes to the shared user data
        NotificationCenter.default.addObserver(forName: UserData.UpdatedNotification, object: nil, queue: nil) { [weak self] (notification) in
            // Update our parked state (which will take care of the rest)
            self?.state = UserData.shared.isParked ? .parked : .driving
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Initial state is based on user data
        self.state = UserData.shared.isParked ? .parked : .driving
        
        // Update our UI
        self.timer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(update(timer:)), userInfo: nil, repeats: true)
        self.timer?.fire()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.timer?.invalidate()
        self.timer = nil
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
    
    // MARK: Handling changes
    
    fileprivate func handleDrawerContentsChanged() {
        if let detailView = self.detailViewController {
            detailView.delegate = self
            detailView.previousLicensePlateNumbers = UserData.shared.otherLicensePlateNumbers
            detailView.licensePlateNumber = UserData.shared.licensePlateNumber
            if let zones = self.mapViewController?.visibleZones {
                detailView.zones = zones
            }
        } else if let parkedView = self.parkedViewController {
            parkedView.delegate = self
            parkedView.licensePlateNumber = UserData.shared.licensePlateNumber
            parkedView.zone = UserData.shared.currentParkedZone
        }
    }
    
    @objc fileprivate func update(timer: Timer) {
        guard self.state == .parked else {
            return
        }
        
        guard let parkedView = self.parkedViewController else {
            return
        }
        
        guard let parkedAt = UserData.shared.parkedAt, let zone = UserData.shared.currentParkedZone else {
            return
        }
        
        let costEstimate = zone.estimatedPrice(from: parkedAt)
        let cost = NSDecimalNumber(value: costEstimate.cost / 100.0)
        
        let attributes: [NSAttributedStringKey: Any] = [
            .font: parkedView.parkingInfoLabel.font,
            .foregroundColor: parkedView.parkingInfoLabel.textColor
        ]
        
        let boldAttributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: parkedView.parkingInfoLabel.font.pointSize, weight: .semibold),
            .foregroundColor: parkedView.parkingInfoLabel.textColor
        ]
        
        let duration = self.durationFormatter.string(from: -parkedAt.timeIntervalSinceNow)!
        let attributedString = NSMutableAttributedString(string: "", attributes: attributes)
        
        // Two lines (first being the actual duration)
        attributedString.append(NSAttributedString(string: "UI.Parked.Info.DurationPrefix".localized(withComment: "Parking duration label prefix"), attributes: attributes))
        attributedString.append(NSAttributedString(string: duration, attributes: boldAttributes))
        
        attributedString.append(NSAttributedString(string: "\n"))
        
        // ... and second being our price estimation
        attributedString.append(NSAttributedString(string: "UI.Parked.Info.CostPrefix".localized(withComment: "Parking cost label prefix"), attributes: attributes))
        attributedString.append(NSAttributedString(string: self.costFormatter.string(from: cost)!, attributes: boldAttributes))
        
        parkedView.parkingInfoLabel.attributedText = attributedString
        parkedView.parkedTimeLabel.text = duration
    }
    
    // MARK: MapViewControllerDelegate
    
    func mapViewController(_ controller: MapViewController, didUpdateVisibleZones zones: [Zone]) {
        guard self.state != .parked else {
            return
        }
        
        let bestMatches = Array(zones[0..<min(zones.count, 3)])
        
        if let zone = self.selectedZone, !bestMatches.contains(zone) {
            self.selectedZone = bestMatches.first
        } else if self.selectedZone == nil {
            self.selectedZone = bestMatches.first
        }
        
        if let detailView = self.drawerContentViewController as? DetailViewController {
            detailView.zones = bestMatches
            detailView.selectedZone = self.selectedZone
        }
    }
    
    // MARK: DetailViewControllerDelegate
    
    func detailViewController(_ controller: DetailViewController, didSelectZone zone: Zone?) {
        guard self.state != .parked else {
            return
        }
        
        self.selectedZone = zone
    }
    
    func detailViewController(_ controller: DetailViewController, didChangeLicensePlateNumber licensePlate: String?) {
        guard self.state != .parked else {
            return
        }
        
        UserData.shared.licensePlateNumber = licensePlate
        
        if let plate = licensePlate {
            UserData.shared.otherLicensePlateNumbers.insert(plate, at: 0)
            controller.previousLicensePlateNumbers = UserData.shared.otherLicensePlateNumbers
        }
    }
    
    func detailViewControllerDidPressParkButton(_ controller: DetailViewController) {
        guard self.state != .parked else {
            return
        }
        
        guard let zone = self.selectedZone, let licensePlate = UserData.shared.licensePlateNumber else {
            return
        }
        
        ParkingManager.shared.startParking(licensePlate: licensePlate, zone: zone, coordinate: self.mapViewController?.currentUserLocation?.coordinate, using: self) { (result) in
            if result == .failed {
                // Failed, we should show an error
                // Show an alert, we can't send SMS
                let alert = UIAlertController(title: "UI.SMSFailed".localized(withComment: "SMSi saatmine ebaõnnestus"), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(withComment: "OK"), style: .default))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: ParkedViewControllerDelegate
    
    func parkedViewControllerDidPressDriveButton(_ controller: ParkedViewController) {
        guard self.state == .parked else {
            return
        }
        
        ParkingManager.shared.endParking()
    }
    
    func parkedViewControllerDidRequestDirections(_ controller: ParkedViewController) {
        guard self.state == .parked else {
            return
        }
        
        guard let coordinate = UserData.shared.currentParkedCoordinate, let zone = UserData.shared.currentParkedZone else {
            return
        }
        
        // Push to Maps
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = zone.code
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
    }
}

