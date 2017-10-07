//
//  ParkedViewController.swift
//  Pargi
//
//  Created by Henri Normak on 01/10/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit
import Pulley

class ParkedViewController: UIViewController, PulleyDrawerViewControllerDelegate {
    
    @IBOutlet var driveButton: UIButton!
    @IBOutlet var directionsButton: UIButton!
    @IBOutlet var licensePlateLabel: UILabel!
    @IBOutlet var zoneNameLabel: UILabel!
    @IBOutlet var parkingInfoLabel: UILabel!
    @IBOutlet var parkedTimeLabel: UILabel!

    var parkedAt: Date? = nil
    var delegate: ParkedViewControllerDelegate? = nil
    
    var licensePlateNumber: String? = nil {
        didSet {            
            // License plate label
            self.licensePlateLabel?.text = self.licensePlateNumber ?? "-"
        }
    }
    
    var zone: Zone? = nil {
        didSet {
            // Update zone label
            self.zoneNameLabel?.text = self.zone?.code
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.driveButton.update(withCallToAction: "UI.CTA.Drive".localized(withComment: "Call to action: Drive"))
        self.directionsButton.update(withSecondaryCallToAction: "UI.CTA.Directions".localized(withComment: "Call to action: Directions"))
    }
    
    // MARK: Actions
    
    @IBAction func tapped(driveButton: UIButton) {
        self.delegate?.parkedViewControllerDidPressDriveButton(self)
    }
    
    @IBAction func tapped(directionsButton: UIButton) {
        self.delegate?.parkedViewControllerDidRequestDirections(self)
    }
        
    // MARK: PulleyDrawerViewControllerDelegate
    
    func collapsedDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 80.0 + bottomSafeArea
    }
    
    func partialRevealDrawerHeight(bottomSafeArea: CGFloat) -> CGFloat {
        return 310.0 + bottomSafeArea
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed]
    }
}

protocol ParkedViewControllerDelegate {
    func parkedViewControllerDidPressDriveButton(_ controller: ParkedViewController)
    func parkedViewControllerDidRequestDirections(_ controller: ParkedViewController)
}
