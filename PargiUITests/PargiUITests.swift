//
//  PargiUITests.swift
//  PargiUITests
//
//  Created by Henri Normak on 01/10/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import XCTest

class PargiUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
        self.acceptDialogs(inApp: app)
        self.endParking(inApp: app)
    }
    
    func wait(interval: Double) {
        let expectation = self.expectation(description: "Wait")
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: interval + 1, handler: nil)
    }
    
    func acceptDialogs(inApp app: XCUIApplication) {
        let notificationQuery = app.alerts["“Pargi” Would Like to Send You Notifications"]
        if notificationQuery.waitForExistence(timeout: 2) {
            notificationQuery.buttons["Allow"].tap()
        }
        
        let gpsQuery = app.alerts["Allow “Pargi” to access your location while you are using the app?"];
        if gpsQuery.waitForExistence(timeout: 2) {
            gpsQuery.buttons["Allow"].tap()
        }
    }
    
    func openDetailView(inApp app: XCUIApplication) {
        let predicate = NSPredicate(format: "label BEGINSWITH 'Pargi'")
        let parkBtn = app.buttons.matching(predicate).firstMatch
        let driveBtn = app.buttons["Sõida"].firstMatch
        
        if parkBtn.exists {
            parkBtn.swipeUp()
        } else if driveBtn.exists {
            driveBtn.swipeUp()
        }
    }
    
    func closeDetailView(inApp app: XCUIApplication) {
        let predicate = NSPredicate(format: "label BEGINSWITH 'Pargi'")
        let parkBtn = app.buttons.matching(predicate).firstMatch
        let driveBtn = app.buttons["Sõida"].firstMatch
        
        if parkBtn.exists {
            parkBtn.swipeDown()
        } else if driveBtn.exists {
            driveBtn.swipeDown()
        }
    }
    
    func endParking(inApp app: XCUIApplication) {
        let driveBtn = app.buttons["Sõida"].firstMatch

        if driveBtn.exists {
            driveBtn.tap()
        }
    }
    
    func setLicensePlate(toValue licensePlate: String, inApp app: XCUIApplication) {
        app.scrollViews.otherElements.buttons["Edit"].tap()
        app.textFields.firstMatch.doubleTap()
        
        if app.menuItems.firstMatch.exists {
            app.menuItems.firstMatch.tap()
        }
        
        app.textFields.firstMatch.typeText(licensePlate)
        app.buttons["Done"].tap()
    }
    
    func testMainView() {
        let app = XCUIApplication()
        
        let elementsQuery = app.scrollViews.otherElements.buttons["KESKLINN15"]
        assert(elementsQuery.waitForExistence(timeout: 30))
        
        snapshot("01-Main")
        self.openDetailView(inApp: app)
        snapshot("02-Main-Expanded")
    }
    
    func testEditLicensePlate() {
        let app = XCUIApplication()

        self.openDetailView(inApp: app)
        self.setLicensePlate(toValue: "123ABC", inApp: app)
        assert(app.scrollViews.otherElements.staticTexts["123ABC"].exists)
    }
    
    func testPark() {
        let app = XCUIApplication()
        
        if !app.buttons["Pargi 123ABC"].exists && app.buttons["Pargi"].exists {
            self.openDetailView(inApp: app)
            self.setLicensePlate(toValue: "123ABC", inApp: app)
            self.closeDetailView(inApp: app)
        }
        
        assert(app.buttons["Pargi 123ABC"].isEnabled)
        app.buttons["Pargi 123ABC"].tap()
        
        self.wait(interval: 2)

        assert(app.buttons["Sõida"].exists)
        
        // Take screenshots
        snapshot("03-Parked")
        
        self.openDetailView(inApp: app)
        snapshot("04-Parked-Expanded")
        
        // Finish parking
        self.endParking(inApp: app)
    }
}
