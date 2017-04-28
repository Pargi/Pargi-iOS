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
