//
//  AppDelegate.swift
//  Pargi
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var locationManager: CLLocationManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Check for DB updates
        ApplicationData.updateDatabase()
        
        // Some general appearance nonsense        
        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: #colorLiteral(red: 0.1098039216, green: 0.1960784314, blue: 0.2666666667, alpha: 1), .font: UIFont.boldSystemFont(ofSize: 17.0)]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        // Location updates
        self.locationManager = CLLocationManager()
        self.locationManager?.requestAlwaysAuthorization()
        
        return true
    }
}
