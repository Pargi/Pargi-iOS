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

class MapViewController: UIViewController, MKMapViewDelegate, PulleyPrimaryContentControllerDelegate {
    @IBOutlet var mapView: MKMapView!
    
    private let mapMaxAltitude: CLLocationDistance = 500.0
    
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
        
    // MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated: Bool) {
        // Make sure our parent (if Pulley), is collapsed
        if let pulley = self.parent as? PulleyViewController, pulley.drawerPosition != .collapsed {
            pulley.setDrawerPosition(position: .collapsed)
        }
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // Update camera (if altitude is higher than expected)
        let existingCamera = mapView.camera
        let altitude = min(existingCamera.altitude, self.mapMaxAltitude)
        
        let coordinate: CLLocationCoordinate2D
        if MKMapRectContainsPoint(mapView.visibleMapRect, MKMapPointForCoordinate(userLocation.coordinate)) && existingCamera.altitude == altitude {
            coordinate = existingCamera.centerCoordinate
        } else {
            coordinate = userLocation.coordinate
        }
        
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: altitude, pitch: existingCamera.pitch, heading: existingCamera.heading)
        mapView.setCamera(camera, animated: true)
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
