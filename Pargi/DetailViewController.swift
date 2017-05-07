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
    
    var licensePlateNumber: String? = nil {
        didSet {
            self.updateParkButton()
            
            // License plate label
            self.licensePlateLabel?.text = self.licensePlateNumber ?? "-"
        }
    }
    
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
            
            // Default selected zone to the first of the new zones
            self.selectedZone = self.zones.first
            
            // If no zones, then unhide the missing zones label
            self.zeroZonesLabel.isHidden = self.zones.count > 0
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
        self.parkButton.setBackgroundImage(UIImage.roundedImage(cornerRadius: 8.0, lineWidth: 2.0, fill: false), for: .normal)
        self.parkButton.setBackgroundImage(UIImage.roundedImage(cornerRadius: 8.0, lineWidth: 2.0, fill: true), for: .highlighted)
    }
    
    // MARK: UI Updates
    
    private func updateParkButton() {
        let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightHeavy)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        var attributes = [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraph, NSForegroundColorAttributeName: self.parkButton.tintColor]
        let buttonTitle = NSMutableAttributedString(string: "UI.CTA.Park".localized(withComment: "Call to action: Park"), attributes: attributes)
        
        if let license = self.licensePlateNumber {
            attributes[NSFontAttributeName] = UIFont.systemFont(ofSize: 10.0, weight: UIFontWeightRegular)
            let licenseTitle = NSAttributedString(string: "\n\(license)", attributes: attributes)
            buttonTitle.append(licenseTitle)
        }
        
        self.parkButton?.titleLabel?.numberOfLines = 0
        self.parkButton?.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .normal)
        
        buttonTitle.addAttributes([NSForegroundColorAttributeName: UIColor.white], range: NSRange(location: 0, length: buttonTitle.length))
        self.parkButton?.setAttributedTitle(buttonTitle, for: .highlighted)
        
        buttonTitle.addAttributes([NSForegroundColorAttributeName: self.parkButton?.tintColor.withAlphaComponent(0.6) as Any], range: NSRange(location: 0, length: buttonTitle.length))
        self.parkButton?.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .disabled)
        
        // Should only be tappable if there is a zone and a license
        self.parkButton.isEnabled = self.selectedZone != nil && self.licensePlateNumber != nil
    }
    
    // MARK: Actions
    
    @IBAction func tapped(zoneButton: UIButton) {
        guard let idx = (zoneButton.superview as? UIStackView)?.arrangedSubviews.index(of: zoneButton) else {
            return
        }
        
        self.selectedZone = self.zones[idx]
    }
    
    // MARK: Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Make sure to pass along the current value to the editor
        if segue.identifier == "changeLicensePlateNumber", let licenseVC = segue.destination as? CarLicenseViewController {
            licenseVC.licensePlateNumber = self.licensePlateNumber
        }
    }
    
    @IBAction func unwindToDetail(segue: UIStoryboardSegue) {
        // If identifier is "licensePlateNumberChanged", then we can obtain the new license plate number from the VC
        if segue.identifier == "licensePlateNumberChanged", let licenseVC = segue.source as? CarLicenseViewController {
            self.licensePlateNumber = licenseVC.licensePlateNumber
        }
    }
    
    // MARK: PulleyDrawerViewControllerDelegate
    
    func collapsedDrawerHeight() -> CGFloat {
        return 75.0
    }
    
    func partialRevealDrawerHeight() -> CGFloat {
        return 300.0
    }
    
    func supportedDrawerPositions() -> [PulleyPosition] {
        return [.collapsed, .partiallyRevealed]
    }
}

protocol DetailViewControllerDelegate {
    func detailViewController(_ controller: DetailViewController, didSelectZone zone: Zone?)
}
