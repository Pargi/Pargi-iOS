//
//  ViewController.swift
//  Pargi
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit
import MapKit
import Pulley

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, PulleyPrimaryContentControllerDelegate {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapPanGesture: UIPanGestureRecognizer!
    @IBOutlet var locateUserButton: UIButton!
    @IBOutlet var locateUserButtonBottomConstraint: NSLayoutConstraint!
    
    private let mapMaxAltitude: CLLocationDistance = 500.0
    private var previousBottomDistance: CGFloat = 0.0
    
    var trackUserLocation: Bool = true
    var currentUserLocation: CLLocation? {
        get {
            guard let location = self.mapView.userLocation.location else {
                return nil
            }
            
            guard CLLocationCoordinate2DIsValid(location.coordinate) else {
                return nil
            }
            
            return location
        }
    }
    
    var isUserInteractionEnabled: Bool {
        get {
            return self.mapView.isUserInteractionEnabled
        }
        
        set {
            self.mapView.isUserInteractionEnabled = newValue
        }
    }
    
    var delegate: MapViewControllerDelegate? = nil
    
    var zones: [Zone] = [] {
        didSet {
            // Cleanup old
            self.mapView.removeOverlays(self.mapView.overlays)
            self.mapView.removeAnnotations(self.mapView.annotations)
            
            // Add new
            let annotations = Array(zones.map({ $0.annotations }).joined())
            let overlays = annotations.filter({ $0.isOverlay })
            let points = annotations.filter({ !$0.isOverlay })
            
            self.mapView.addOverlays(overlays)
            self.mapView.addAnnotations(points)
        }
    }
    
    var visibleZones: [Zone] = []
    
    // MARK: Actions
    
    @IBAction func mapPanned(gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended else {
            return
        }
        
        // Stop trackign user location and show button for centering
        self.locateUserButton.isHidden = false
        self.trackUserLocation = false
        
        // Panning has finished, update our visible zones listing
        self.updateVisibleZones()
    }
    
    @IBAction func locateUser(_ sender: UIButton) {
        self.moveCameraToUserLocation(animated: true) { _ in sender.isHidden = true }
    }
    
    // MARK: Helpers
    
    fileprivate func moveCameraToUserLocation(animated: Bool, completion: ((_ success: Bool) -> Void)? = nil) {
        guard let currentUserLocation = self.currentUserLocation else {
            return
        }
        
        let camera = self.mapView.camera
        let altitude = min(camera.altitude, self.mapMaxAltitude)
        let center = self.visualCenterCoordinate(forCoordinate: currentUserLocation.coordinate, andAltitude: altitude)
        let newCamera = MKMapCamera(lookingAtCenter: center, fromDistance: altitude, pitch: camera.pitch, heading: 0)
        
        UIView.animate(withDuration: animated ? 0.2 : 0, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.mapView.camera = newCamera
        }) { success in
            self.updateVisibleZones()
            self.trackUserLocation = true
            completion?(success)
        }
    }
    
    fileprivate func updateVisibleZones() {
        // Figure out which zones are now visible
        let visibleMapRect = self.mapView.visibleMapRect
        let paddedMapRect = self.mapView.mapRectThatFits(visibleMapRect, edgePadding: .zero)
        
        let annotations = self.mapView.annotations(in: paddedMapRect)
        let overlays = self.mapView.overlays.filter({ overlay in
            return MKMapRectIntersectsRect(overlay.boundingMapRect, paddedMapRect)
        })
        
        let zones = annotations.compactMap({ ($0 as? Annotation)?.zone }) + overlays.compactMap({ ($0 as? Annotation)?.zone })
        let uniqueZones = zones.reduce([]) { $0.contains($1) ? $0 : $0 + [$1] }
        
        // Sort the zones based on distance from the center (unless we are inside of them, in which case the distance is equivalent to 0)
        let coordinate = self.mapView.userLocation.coordinate
        let sorted = uniqueZones.sorted { (a, b) -> Bool in
            guard a.isPoint && b.isPoint else {
                return a.contains(coordinate: coordinate) && !b.contains(coordinate: coordinate)
            }
            
            return a.distance(from: coordinate) < b.distance(from: coordinate)
        }
        
        self.visibleZones = sorted
        self.delegate?.mapViewController(self, didUpdateVisibleZones: sorted)
    }
    
    fileprivate func uncoveredMapFrame() -> CGRect {
        guard let pulley = self.parent as? PulleyViewController, let drawer = pulley.drawerContentViewController else {
            return self.mapView.frame
        }
        
        let drawerRect = self.view.convert(drawer.view.frame, from: drawer.view.superview)
        let mapViewRect = self.view.convert(self.mapView.frame, from: self.mapView.superview)
        
        guard mapViewRect.maxY > drawerRect.minY else {
            return self.mapView.frame
        }
        
        let offset: CGFloat
        if #available(iOS 11.0, *) {
            offset = self.view.safeAreaInsets.bottom
        } else {
            offset = self.bottomLayoutGuide.length
        }
        
        return CGRect(origin: mapViewRect.origin, size: CGSize(width: mapViewRect.width, height: drawerRect.minY - mapViewRect.minY + offset))
    }
    
    fileprivate func visualCenterCoordinate(
        forCoordinate coordinate: CLLocationCoordinate2D,
        andAltitude altitude: CLLocationDistance
    ) -> CLLocationCoordinate2D {
        // Determine offset in points
        let mapFrame = self.mapView.frame
        let uncoveredFrame = self.uncoveredMapFrame()
        let offset = mapFrame.midY - uncoveredFrame.midY

        // Determine the offset in meters (for current camera altitude)
        let currentCenter = self.mapView.centerCoordinate
        let currentCenterPoint = self.mapView.convert(currentCenter, toPointTo: self.mapView.superview)
        let adjustedCenter = self.mapView.convert(CGPoint(x: currentCenterPoint.x, y: currentCenterPoint.y - offset), toCoordinateFrom: self.mapView.superview)
        
        let distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(currentCenter), MKMapPointForCoordinate(adjustedCenter))
        let altitudeRatio = distance / self.mapView.camera.altitude
        
        // Use the distance/ratio to determine the adjusted center at given coordinate and altitude
        let mapPoint = MKMapPointForCoordinate(coordinate)
        var result = mapPoint
        result.y += MKMapPointsPerMeterAtLatitude(coordinate.latitude) * altitudeRatio * altitude
        
        return MKCoordinateForMapPoint(result)
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: PulleyPrimaryContentControllerDelegate
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        // Update our "visible area" on the map
        let delta = (distance - bottomSafeArea - self.previousBottomDistance) / 2
        
        // Determine the center point of the new visible area
        let newCenter = CGPoint(x: self.mapView.frame.midX, y: self.mapView.frame.midY + delta)
        let coordinate = self.mapView.convert(newCenter, toCoordinateFrom: self.mapView.superview)
        
        let existingCamera = self.mapView.camera
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: existingCamera.altitude, pitch: existingCamera.pitch, heading: existingCamera.heading)
        self.mapView.setCamera(camera, animated: false)
        
        self.previousBottomDistance = distance
        
        // Update user location centering button coordinates based on drawer height
        locateUserButtonBottomConstraint.constant = -distance
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        // Update our visible zones
        self.updateVisibleZones()
        
        // Update the locate button constraint
        if let drawerVC = drawer.drawerContentViewController, let primaryVC = drawer.primaryContentViewController {
            let drawerFrame = drawer.view.convert(drawerVC.view.bounds, from: drawerVC.view)
            let primaryFrame = drawer.view.convert(primaryVC.view.bounds, from: primaryVC.view)
            
            locateUserButtonBottomConstraint.constant = min(drawerFrame.minY - primaryFrame.maxY, 0)
        }
        
        // Calling this after drawer has changed, as it will break drawer opening if called in ’drawerChangedDistanceFromBottom’
        self.view.setNeedsUpdateConstraints()
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // Ignore if we are not to follow user
        guard self.trackUserLocation else {
            return
        }
        
        self.moveCameraToUserLocation(animated: true)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let annotation = overlay as? Annotation, let polygon = annotation.polygon else {
            return MKOverlayRenderer(overlay: overlay)
        }
        
        let renderer = MKPolygonRenderer(polygon: polygon)
        renderer.lineWidth = 2.0
        
        if let provider = ApplicationData.currentDatabase.provider(for: annotation.zone) {
            renderer.strokeColor = provider.color.withAlphaComponent(0.6)
            renderer.fillColor = provider.color.withAlphaComponent(0.15)
        } else {
            renderer.strokeColor = self.view.tintColor.withAlphaComponent(0.6)
            renderer.fillColor = self.view.tintColor.withAlphaComponent(0.15)
        }
        
        return renderer
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Annotation, let point = annotation.point else {
            return nil
        }
        
        var view: AnnotationView
        if let existing = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? AnnotationView {
            view = existing
            view.annotation = point
        } else {
            view = AnnotationView(annotation: point, reuseIdentifier: "pin")
        }
        
        if let provider = ApplicationData.currentDatabase.provider(for: annotation.zone) {
            view.tintColor = provider.color
        } else {
            view.tintColor = nil
        }
        
        return view
    }
}

protocol MapViewControllerDelegate {
    func mapViewController(_ controller: MapViewController, didUpdateVisibleZones zones: [Zone])
}
