//
//  DetailViewController.swift
//  Pargi
//
//  View controller in charge of the detail part of the main
//  interface. Main user interactions will go through this,
//  but are not actually handled in here.
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import UIKit
import Pulley

class DetailViewController: UIViewController, PulleyDrawerViewControllerDelegate {
    
    @IBOutlet var zoneStackView: UIStackView!
    @IBOutlet var parkButton: UIButton!
    @IBOutlet var zeroZonesLabel: UILabel!
    @IBOutlet var licensePlateLabel: UILabel!
    
    // Selected zone information
    @IBOutlet var zoneTariffLabel: UILabel!
    
    var delegate: DetailViewControllerDelegate? = nil
    
    // Default license plate number to use
    var licensePlateNumber: String? = nil {
        didSet {
            self.updateParkButton()
            
            // License plate label
            self.licensePlateLabel?.text = self.licensePlateNumber ?? "-"
        }
    }
    
    // Previously used license plate numbers, which can be used as shortcuts
    var previousLicensePlateNumbers: [String]? = nil
    
    var selectedZone: Zone? = nil {
        didSet {
            // Modify buttons so that the selected one stands out
            if let zone = self.selectedZone, let index = self.zones.index(of: zone) {
                for (idx, view) in self.zoneStackView.arrangedSubviews.enumerated() {
                    guard let btn = view as? UIButton else {
                        continue
                    }
                    
                    btn.alpha = index == idx ? 1.0 : 0.4
                }
            } else {
                // No zone selected
                self.zoneStackView.arrangedSubviews.forEach({ view in
                    guard let btn = view as? UIButton else {
                        return
                    }
                    
                    btn.alpha = 0.4
                })
            }
            
            // Park button
            self.updateParkButton()
            
            // Update tariff label (attributed)
            if let attributed = self.selectedZone?.localizedTariffDescription().attributedCaption() {
                self.zoneTariffLabel.attributedText = attributed
            } else {
                self.zoneTariffLabel.text = "-"
            }
            
            // Let our delegate know
            self.delegate?.detailViewController(self, didSelectZone: self.selectedZone)
        }
    }
    
    // List of zones to allow the user to choose from, about 3 or so will suffice
    // (limit will be enforced by not displaying more than we have buttons available)
    var zones: [Zone] = [] {
        didSet {
            self.updateZoneButtons()
            
            // Default selected zone to the first of the new zones (if current selection is not present)
            if let currentSelectedZone = self.selectedZone, self.zones.index(of: currentSelectedZone) == nil {
                self.selectedZone = self.zones.first
            } else if self.selectedZone == nil {
                self.selectedZone = self.zones.first
            }
        }
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Missing zones label
        self.zeroZonesLabel.text = "UI.NoZonesFound".localized(withComment: "No zones where found")
        
        // License plate label
        self.licensePlateLabel.text = self.licensePlateNumber ?? "-"
        
        // Update park button
        self.updateParkButton()
        
        // Update zone buttons
        self.updateZoneButtons()
    }
    
    // MARK: UI Updates
    
    private func updateParkButton() {
        let action = "UI.CTA.Park".localized(withComment: "Call to action: Park")
        let detail = self.licensePlateNumber
        
        self.parkButton?.update(withCallToAction: action, andDetail: detail)
        
        // Should only be tappable if there is a zone and a license
        self.parkButton.isEnabled = self.selectedZone != nil && self.licensePlateNumber != nil
    }
    
    private func updateZoneButtons() {
        // Update up-to n buttons (as many as we have in the stack view)
        for (idx, view) in self.zoneStackView.arrangedSubviews.enumerated() {
            guard let btn = view as? UIButton else {
                continue
            }
            
            if self.zones.count <= idx {
                btn.isHidden = true
                continue
            }
            
            let zone = self.zones[idx]
            let provider = ApplicationData.currentDatabase.provider(for: zone)
            btn.backgroundColor = provider?.color
            btn.setTitle(zone.code, for: .normal)
            btn.isHidden = false
        }
        
        // If no zones, then unhide the missing zones label
        self.zeroZonesLabel.isHidden = self.zones.count > 0
    }
    
    // MARK: Actions
    
    @IBAction func tapped(zoneButton: UIButton) {
        guard let idx = (zoneButton.superview as? UIStackView)?.arrangedSubviews.index(of: zoneButton) else {
            return
        }
        
        self.selectedZone = self.zones[idx]
    }
    
    @IBAction func tapped(parkButton: UIButton) {
        self.delegate?.detailViewControllerDidPressParkButton(self)
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Make sure to pass along the current value to the editor
        if segue.identifier == "changeLicensePlateNumber", let licenseVC = segue.destination as? CarLicenseViewController {
            licenseVC.licensePlateNumber = self.licensePlateNumber
            licenseVC.shortcutLicensePlateNumbers = self.previousLicensePlateNumbers ?? []
        }
    }
    
    @IBAction func unwindToDetail(segue: UIStoryboardSegue) {
        // If identifier is "licensePlateNumberChanged", then we can obtain the new license plate number from the VC
        if segue.identifier == "licensePlateNumberChanged", let licenseVC = segue.source as? CarLicenseViewController {
            self.licensePlateNumber = licenseVC.licensePlateNumber
            self.delegate?.detailViewController(self, didChangeLicensePlateNumber: licenseVC.licensePlateNumber)
        }
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

protocol DetailViewControllerDelegate {
    func detailViewController(_ controller: DetailViewController, didSelectZone zone: Zone?)
    func detailViewController(_ controller: DetailViewController, didChangeLicensePlateNumber licensePlate: String?)
    func detailViewControllerDidPressParkButton(_ controller: DetailViewController)
}
