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
    
    // Selected zone information
    @IBOutlet var zoneTariffLabel: UILabel!
    
    var delegate: DetailViewControllerDelegate? = nil
    
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
            
            // Park button should be enabled only if we have a selected zone
            self.parkButton.isEnabled = self.selectedZone != nil
            
            // Update tariff label (attributed)
            self.zoneTariffLabel.attributedText = self.selectedZone?.localizedTariffDescription().attributedCaption()
            
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
        
        // Update park button
        let font = UIFont.systemFont(ofSize: 14.0, weight: UIFontWeightHeavy)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        var attributes = [NSFontAttributeName: font, NSParagraphStyleAttributeName: paragraph]
        let buttonTitle = NSMutableAttributedString(string: "UI.CTA.Park".localized(withComment: "Call to action: Park"), attributes: attributes)
        
        attributes[NSFontAttributeName] = UIFont.systemFont(ofSize: 10.0, weight: UIFontWeightRegular)
        let licenseTitle = NSAttributedString(string: "\nPROOV123", attributes: attributes)
        buttonTitle.append(licenseTitle)
        
        self.parkButton.titleLabel?.numberOfLines = 0
        self.parkButton.setAttributedTitle(buttonTitle, for: .normal)
    }
    
    // MARK: Actions
    
    @IBAction func tapped(zoneButton: UIButton) {
        guard let idx = (zoneButton.superview as? UIStackView)?.arrangedSubviews.index(of: zoneButton) else {
            return
        }
        
        self.selectedZone = self.zones[idx]
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
