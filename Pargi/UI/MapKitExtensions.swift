//
//  MapKitExtensions.swift
//  Pargi
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import MapKit

class Annotation: NSObject, MKOverlay {
    let color: UIColor
    let title: String?
    let subtitle: String?
    
    let zone: Zone
    
    let isOverlay: Bool
    let polygon: MKPolygon?
    let point: MKPointAnnotation?
    
    init(region: Zone.Region, zone: Zone) {
        self.zone = zone
        
        self.color = UIColor.red
        self.title = zone.code
        self.subtitle = nil
        
        if let overlay = region.polygon {
            self.isOverlay = true
            self.polygon = overlay
            self.point = nil
        } else {
            self.isOverlay = false
            self.polygon = nil
            self.point = region.annotation
        }
    }
    
    // From MKAnnotation, for areas this should return the centroid of the area.
    var coordinate: CLLocationCoordinate2D {
        get {
            return self.isOverlay ? self.polygon!.coordinate : self.point!.coordinate
        }
    }
    
    // boundingMapRect should be the smallest rectangle that completely contains the overlay.
    // For overlays that span the 180th meridian, boundingMapRect should have either a negative MinX or a MaxX that is greater than MKMapSizeWorld.width.
    var boundingMapRect: MKMapRect {
        get {
            guard !self.isOverlay else {
                return self.polygon!.boundingMapRect
            }
            
            let point = MKMapPointForCoordinate(self.point!.coordinate)
            return MKMapRectMake(point.x, point.y, 0.0, 0.0)
        }
    }
    
    func canReplaceMapContent() -> Bool {
        return false
    }
}

extension Zone {
    var annotations: [Annotation] {
        get {
            return self.regions.map({ Annotation(region: $0, zone: self) })
        }
    }
}

fileprivate extension Zone.Region {
    var annotation: MKPointAnnotation? {
        get {
            guard self.points.count > 0 else {
                return nil
            }
            
            if let point = self.points.first, self.points.count == 1 {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                
                return annotation
            }
            
            return nil
        }
    }
    
    var polygon: MKPolygon? {
        get {
            guard self.points.count >= 2 else {
                return nil
            }
            
            let coordinates = self.points.map({ CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) })
            let interiorPolygons = self.interiorRegions.flatMap({ return $0.polygon })
            
            return MKPolygon(coordinates: coordinates, count: coordinates.count, interiorPolygons: interiorPolygons)
        }
    }
}
