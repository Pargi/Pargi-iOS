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
    
    private let mapMaxAltitude: CLLocationDistance = 500.0
    private var previousBottomDistance: CGFloat = 0.0
    
    var trackUserLocation: Bool = true
    var currentUserLocation: CLLocation? {
        get {
            return self.mapView.userLocation.location
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
        
        // Panning has finished, update our visible zones listing
        self.updateVisibleZones()
    }
    
    // MARK: Helpers
    
    fileprivate func updateVisibleZones() {
        // Figure out which zones are now visible
        let visibleMapRect = self.mapView.visibleMapRect
        let paddedMapRect = self.mapView.mapRectThatFits(visibleMapRect, edgePadding: .zero)
        
        let annotations = self.mapView.annotations(in: paddedMapRect)
        let overlays = self.mapView.overlays.filter({ overlay in
            return MKMapRectIntersectsRect(overlay.boundingMapRect, paddedMapRect)
        })
        
        let zones = annotations.flatMap({ ($0 as? Annotation)?.zone }) + overlays.flatMap({ ($0 as? Annotation)?.zone })
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
        
        return CGRect(origin: mapViewRect.origin, size: CGSize(width: mapViewRect.width, height: drawerRect.minY - mapViewRect.minY))
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    // MARK: PulleyPrimaryContentControllerDelegate
    
    func drawerChangedDistanceFromBottom(drawer: PulleyViewController, distance: CGFloat, bottomSafeArea: CGFloat) {
        // Update our "visible area" on the map
        let delta = (distance + bottomSafeArea - self.previousBottomDistance) / 2
        
        // Determine the center point of the new visible area
        let newCenter = CGPoint(x: self.mapView.frame.midX, y: self.mapView.frame.midY + delta)
        let coordinate = self.mapView.convert(newCenter, toCoordinateFrom: self.mapView.superview)
        
        let existingCamera = self.mapView.camera
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: existingCamera.altitude, pitch: existingCamera.pitch, heading: existingCamera.heading)
        self.mapView.setCamera(camera, animated: false)
        
        self.previousBottomDistance = distance + bottomSafeArea
    }
    
    func drawerPositionDidChange(drawer: PulleyViewController, bottomSafeArea: CGFloat) {
        // Update our visible zones
        self.updateVisibleZones()
    }
    
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // Ignore if we are not to follow user
        guard self.trackUserLocation else {
            return
        }
        
        // Determine visual offset of the center coordinate
        let mapFrame = self.mapView.frame
        let uncoveredFrame = self.uncoveredMapFrame()
        let offset = mapFrame.midY - uncoveredFrame.midY
        
        // Update camera (if altitude is higher than expected)
        let existingCamera = mapView.camera
        let altitude = min(existingCamera.altitude, self.mapMaxAltitude)
        let coordinate = userLocation.coordinate
        
        // Correct the coordinate for visual offset (caused by the drawer)
        var point = self.mapView.convert(coordinate, toPointTo: self.view)
        point.y += offset
        let offsetCoordinate = self.mapView.convert(point, toCoordinateFrom: self.view)
        
        // Change the camera
        let camera = MKMapCamera(lookingAtCenter: offsetCoordinate, fromDistance: altitude, pitch: existingCamera.pitch, heading: existingCamera.heading)
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction, .curveEaseInOut], animations: {
            self.mapView.camera = camera
        }) { success in
            self.updateVisibleZones()
        }
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
