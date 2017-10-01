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
import CallKit
import MapKit

class MainViewController: PulleyViewController, MapViewControllerDelegate, DetailViewControllerDelegate, ParkedViewControllerDelegate, MFMessageComposeViewControllerDelegate {
    private var selectedZone: Zone? = nil
    
    // Search button
    @IBOutlet var searchButton: UIBarButtonItem!
    
    // Observing state to figure out whether call was placed
    private var callObserver: CXCallObserver? = nil
    
    enum ParkedState {
        case driving
        case parked
    }
    
    // Updating parking info
    lazy fileprivate var timer: Timer = Timer(timeInterval: 30.0, target: self, selector: #selector(update(timer:)), userInfo: nil, repeats: true)
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
            self.timer.fire()
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
            self.searchButton.hidden = true
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Initial state is based on user data
        self.state = UserData.shared.isParked ? .parked : .driving
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
    
    fileprivate func handleSMSSent(withResult result: MessageComposeResult) {
        switch result {
        case .sent:
            guard let zone = self.selectedZone else {
                // Should never occur, however, to be safe
                let alert = UIAlertController(title: "UI.ParkingFailedNoZone".localized(withComment: "Tundmatu tsoon"), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(withComment: "OK"), style: .default))
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            // Kick off parking tracking
            UserData.shared.startParking(withZone: zone, andCoordinate: self.mapViewController?.currentUserLocation?.coordinate)
            
            // Change state to parked
            self.state = .parked
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
    
    fileprivate func handleDrawerContentsChanged() {
        if let detailView = self.detailViewController {
            detailView.delegate = self
            detailView.previousLicensePlateNumbers = UserData.shared.otherLicensePlateNumbers
            detailView.licensePlateNumber = UserData.shared.licensePlateNumber
            if let zones = self.mapViewController?.visibleZones {
                detailView.zones = zones
            }
        } else if let parkedView = self.parkedViewController {
            // TODO: Hook up delegate and pass along data
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
        
        let duration = -parkedAt.timeIntervalSinceNow
        let attributedString = NSMutableAttributedString(string: "", attributes: attributes)
        
        // Two lines (first being the actual duration)
        attributedString.append(NSAttributedString(string: "UI.Parked.Info.DurationPrefix".localized(withComment: "Parking duration label prefix"), attributes: attributes))
        attributedString.append(NSAttributedString(string: self.durationFormatter.string(from: duration)!, attributes: boldAttributes))
        
        attributedString.append(NSAttributedString(string: "\n"))
        
        // ... and second being our price estimation
        attributedString.append(NSAttributedString(string: "UI.Parked.Info.CostPrefix".localized(withComment: "Parking cost label prefix"), attributes: attributes))
        attributedString.append(NSAttributedString(string: self.costFormatter.string(from: cost)!, attributes: boldAttributes))
        
        parkedView.parkingInfoLabel.attributedText = attributedString
    }
    
    // MARK: MapViewControllerDelegate
    
    func mapViewController(_ controller: MapViewController, didUpdateVisibleZones zones: [Zone]) {
        guard self.state != .parked else {
            return
        }
        
        let bestMatches = Array(zones[0..<min(zones.count, 3)])
        
        if let detailView = self.drawerContentViewController as? DetailViewController {
            detailView.zones = bestMatches
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
        
        #if IOS_SIMULATOR
            // Simulate a successful SMS sent
            self.handleSMSSent(withResult: .sent)
        #else
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
        #endif
    }
    
    // MARK: ParkedViewControllerDelegate
    
    func parkedViewControllerDidPressDriveButton(_ controller: ParkedViewController) {
        guard self.state == .parked else {
            return
        }
        
        #if IOS_SIMULATOR
            // Immediately end parking
            self.state = .driving
            UserData.shared.endParking()
        #else
            // Start observing calls for an indication that the call was actually placed
            // TODO: This doesn't handle the case where user presses cancel and then places a separate outgoing
            // phone call, in which case we'd consider the parking ended - this is an edge case not worthy of immediate work
            let observer = CXCallObserver()
            observer.setDelegate(self, queue: nil)
            self.callObserver = observer
            
            UIApplication.shared.open(URL.endParkingPhoneNumber, options: [:], completionHandler: nil)
        #endif
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
    
    // MARK: MFMessageComposeViewControllerDelegate
    
    public func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {        
        // Dismiss the composer
        self.presentedViewController?.dismiss(animated: true, completion: nil)
        self.handleSMSSent(withResult: result)
    }
}

extension MainViewController: CXCallObserverDelegate {
    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        guard let state = self.state, state == .parked else {
            return
        }
        
        // We only care about outgoing calls and ones that have connected (i.e are not dialing)
        guard call.isOutgoing, call.hasConnected else {
            return
        }
        
        // Assume this call was the one we wanted to trigger, and transition state)
        self.state = .driving
        UserData.shared.endParking()
        
        // Cleanup
        self.callObserver?.setDelegate(nil, queue: nil)
        self.callObserver = nil
    }
}
