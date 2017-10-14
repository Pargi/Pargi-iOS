//
//  AppDelegate.swift
//  Pargi
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    let backgroundQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "UserData Updates"
        return queue
    }()
    
    struct NotificationIdentifiers {
        static let EndParking = "EndParking"
    }
    
    struct NotificationActions {
        static let EndParking = "EndParking"
    }
    
    struct NotificationCategory {
        static let Parked = "Parked"
    }
    
    var window: UIWindow?
    var locationManager: CLLocationManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Check for DB updates
        ApplicationData.updateDatabase()
        
        // Observe user data
        NotificationCenter.default.addObserver(forName: UserData.UpdatedNotification, object: nil, queue: self.backgroundQueue, using: self.handleUpdate)
        
        // Some general appearance nonsense        
        let attributes: [NSAttributedStringKey: Any] = [.foregroundColor: #colorLiteral(red: 0.1098039216, green: 0.1960784314, blue: 0.2666666667, alpha: 1), .font: UIFont.boldSystemFont(ofSize: 17.0)]
        UINavigationBar.appearance().titleTextAttributes = attributes
        
        self.locationManager = CLLocationManager()

        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        
        // Request access to notifications
        notificationCenter.requestAuthorization(options: [.alert, .sound]) {(accepted, error) in
            // Request access to location updates
            self.locationManager?.requestWhenInUseAuthorization()
        }
        
        // Configure user notifications
        let endParkingAction = UNNotificationAction(identifier: NotificationActions.EndParking,
                                                    title: "UI.Notification.Action.EndParking".localized(withComment: "CTA: End parking via notification action"),
                                                    options: [.foreground])
        let category = UNNotificationCategory(identifier: NotificationCategory.Parked,
                                              actions: [endParkingAction],
                                              intentIdentifiers: [],
                                              options: [.allowInCarPlay])
        
        notificationCenter.setNotificationCategories([category])
        
        return true
    }
    
    // MARK: Handle UserData updates
    
    func handleUpdate(notification: Notification) {
        guard let object = notification.object, let userData = object as? UserData else {
            return
        }
        
        guard let oldUserData = notification.userInfo?[UserData.OldUserDataKey] as? UserData else {
            return
        }
        
        // No point in reacting to anything if we are not allowed to monitor location updates
        guard [.authorizedWhenInUse, .authorizedAlways].contains(CLLocationManager.authorizationStatus()) else {
            return
        }
        
        // When we started parking, we want to start monitoring
        if userData.isParked, !oldUserData.isParked, let coordinate = userData.currentParkedCoordinate {
            let content = UNMutableNotificationContent()
            content.title = "UI.Notification.Distance.Title".localized(withComment: "Notification title: End parking")
            content.body = "UI.Notification.Distance.Body".localized(withComment: "Notification body: End Parking")
            content.sound = UNNotificationSound.default()
            content.categoryIdentifier = NotificationCategory.Parked
            
            let region = CLCircularRegion(center: coordinate, radius: 750, identifier: NotificationIdentifiers.EndParking)
            region.notifyOnExit = true
            
            let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
            
            let request = UNNotificationRequest(identifier: NotificationIdentifiers.EndParking, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error) in
                if let error = error {
                    print("Error scheduling notification request \(error)")
                }
            }
        }
        
        // When we ended parking, we want to stop monitoring
        if !userData.isParked, oldUserData.isParked {
            print("Remove pending notification requests")
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [NotificationIdentifiers.EndParking])
        }
    }
    
    // MARK: UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard response.actionIdentifier == NotificationActions.EndParking else {
            completionHandler()
            return
        }
        
        // End parking
        ParkingManager.shared.endParking() { _ in
            completionHandler()
        }
    }
}
