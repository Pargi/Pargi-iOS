//
//  CarLicenseViewController.swift
//  Pargi
//
//  Created by Henri Normak on 07/05/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit

class CarLicenseViewController: UIViewController {
    @IBOutlet private var textField: UITextField!
    @IBOutlet private var textFieldInputView: UIView!
    
    @IBOutlet private var shortcutLicensePlatesStackView: UIStackView!
    
    var licensePlateNumber: String? {
        didSet {
            self.textField?.text = self.licensePlateNumber
        }
    }
    
    var shortcutLicensePlateNumbers: [String] = [] {
        didSet {
            self.updateShortcutLicensePlateNumbers()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.text = self.licensePlateNumber
        self.textField.inputAccessoryView = self.textFieldInputView
        
        self.updateShortcutLicensePlateNumbers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.becomeFirstResponder()
    }
    
    // MARK: UI Updates
    
    private func updateShortcutLicensePlateNumbers() {
        // Clear old plates
        if let subviews = self.shortcutLicensePlatesStackView?.subviews {
            for subview in subviews {
                subview.removeFromSuperview()
            }
        }
        
        // Create new ones
        for number in self.shortcutLicensePlateNumbers {
            let button = UIButton(type: .system)
            button.setTitle(number, for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 30.0, bottom: 0.0, right: 30.0)
            button.setContentCompressionResistancePriority(UILayoutPriorityRequired, for: .horizontal)
            button.addTarget(self, action: #selector(shortcutLicensePlateTapped(sender:)), for: .touchUpInside)
            
            self.shortcutLicensePlatesStackView?.addArrangedSubview(button)
        }
    }
    
    // MARK: Actions
    
    @IBAction func returnKeyPressed(textField: UITextField) {
        // Enforce uppercase
        textField.text = textField.text?.uppercased()
        self.licensePlateNumber = textField.text
        
        // Cue rewind segue
        self.performSegue(withIdentifier: "licensePlateNumberChanged", sender: textField)
    }
    
    @objc func shortcutLicensePlateTapped(sender: UIButton) {
        self.licensePlateNumber = sender.titleLabel?.text
        
        // Cue rewind segue
        self.performSegue(withIdentifier: "licensePlateNumberChanged", sender: sender)
    }
}
