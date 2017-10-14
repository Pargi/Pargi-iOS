//
//  ParkingManager.swift
//  Pargi
//
//  Helper for starting/ending parking
//
//  Created by Henri Normak on 07/10/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit
import MessageUI
import CallKit
import CoreLocation

class ParkingManager: NSObject {
    
    static let shared = ParkingManager()
    
    fileprivate var zone: Zone?
    fileprivate var coordinate: CLLocationCoordinate2D?
    fileprivate var callObserver: CXCallObserver?
    fileprivate let callQueue = OperationQueue()
    
    fileprivate var startBlock: ((MessageComposeResult) -> Void)?
    fileprivate var endBlock: ((Bool) -> Void)?
    
    func startParking(licensePlate: String, zone: Zone, coordinate: CLLocationCoordinate2D? = nil, using viewController: UIViewController, completion: ((MessageComposeResult) -> Void)? = nil) {
        // If already parked, no point to try again
        guard !UserData.shared.isParked else {
            completion?(.failed)
            return
        }
        
        #if FAKE_PARKING
            UserData.shared.startParking(withZone: zone, andCoordinate: coordinate)
            completion?(.sent)
            return
        #else
            // If can't send SMS, no point to try
            guard MFMessageComposeViewController.canSendText() else {
                // Show an alert, we can't send SMS
                let alert = UIAlertController(title: "UI.NoSMSCapability".localized(withComment: "SMSi saatmine ebaõnnestus"), message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK".localized(withComment: "OK"), style: .default))
                viewController.present(alert, animated: true) {
                    completion?(.failed)
                }
                
                return
            }
            
            self.zone = zone
            self.coordinate = coordinate
            self.startBlock = completion
            let composeController = MFMessageComposeViewController(licensePlate: licensePlate, zone: zone)
            composeController.messageComposeDelegate = self
            viewController.present(composeController, animated: true, completion: nil)
        #endif
    }
    
    func endParking(completion: ((Bool) -> Void)? = nil) {
        // If not parked, no point to try
        guard UserData.shared.isParked else {
            DispatchQueue.main.async {
                completion?(false)
            }
            return
        }
        
        #if FAKE_PARKING
            UserData.shared.endParking()
            DispatchQueue.main.async {
                completion?(true)
            }
            return
        #else
            // Start observing calls for an indication that the call was actually placed
            // TODO: This doesn't handle the case where user presses cancel and then places a separate outgoing
            // phone call, in which case we'd consider the parking ended - this is an edge case not worthy of immediate work
            let observer = CXCallObserver()
            observer.setDelegate(self, queue: nil)
            self.callObserver = observer
            self.endBlock = completion
            
            UIApplication.shared.open(URL.endParkingPhoneNumber, options: [:], completionHandler: nil)
        #endif
    }
}

extension ParkingManager: CXCallObserverDelegate {
    public func callObserver(_ callObserver: CXCallObserver, callChanged call: CXCall) {
        // We only care about outgoing calls and ones that have connected (i.e are not dialing)
        guard call.isOutgoing, call.hasConnected else {
            return
        }
        
        // Assume this call was the one we wanted to trigger and end parking
        UserData.shared.endParking()
        
        // Cleanup
        self.callObserver?.setDelegate(nil, queue: nil)
        self.callObserver = nil
        
        // Call our completion block
        if let completion = self.endBlock {
            DispatchQueue.main.async {
                completion(true)
                self.endBlock = nil
            }
        }
    }
}

extension ParkingManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true) {
            if let zone = self.zone, result == .sent {
                UserData.shared.startParking(withZone: zone, andCoordinate: self.coordinate)
            }
            
            if let completion = self.startBlock {
                DispatchQueue.main.async {
                    completion(result)
                    self.startBlock = nil
                }
            }
        }
    }
}
