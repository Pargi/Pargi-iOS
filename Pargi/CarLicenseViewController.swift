//
//  CarLicenseViewController.swift
//  Pargi
//
//  Created by Henri Normak on 07/05/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit

class CarLicenseViewController: UIViewController {
    @IBOutlet var textField: UITextField!
    
    var licensePlateNumber: String? {
        didSet {
            self.textField?.text = self.licensePlateNumber
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textField.text = self.licensePlateNumber
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.textField.becomeFirstResponder()
    }
    
    // MARK: Actions
    
    @IBAction func returnKeyPressed(textField: UITextField) {
        // Enforce uppercase
        textField.text = textField.text?.uppercased()
        self.licensePlateNumber = textField.text
        
        // Cue rewind segue
        self.performSegue(withIdentifier: "licensePlateNumberChanged", sender: textField)
    }
}
