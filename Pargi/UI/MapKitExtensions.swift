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
    
    var isPoint: Bool {
        return self.regions.count == 1 && self.regions.first?.points.count == 1
    }
    
    ///
    /// Determine whether the zone contains a location or not
    /// Keep in mind that if a zone is a point, then the coordinate
    /// can never be "contained" and as such this always returns false
    /// when .isPoint == true
    ///
    /// Similarly always false for zones with no regions
    ///
    func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        guard !self.isPoint else {
            return false
        }
        
        guard self.regions.count >= 1 else {
            return false
        }
        
        // Find the first region that contains (if there is one, that is also proof that we contain)
        return self.regions.first(where: { (region) in
            return region.contains(coordinate: coordinate)
        }) != nil
    }
    
    ///
    /// If Zone is a point, then distance from it, if a region, then distance from the
    /// (combined if multiple) centroid
    ///
    func distance(from: CLLocationCoordinate2D) -> CLLocationDistance {
        let coordinates = self.regions.map({ $0.centerCoordinate })
        
        guard coordinates.count > 1 else {
            if let first = coordinates.first {
                let p1 = MKMapPointForCoordinate(from)
                let p2 = MKMapPointForCoordinate(first)
                
                return MKMetersBetweenMapPoints(p1, p2)
            }
            
            return CLLocationDistanceMax
        }
        
        // More than one coordinate, create a temp polygon and find the distance to its center
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        let p1 = MKMapPointForCoordinate(from)
        let p2 = MKMapPointForCoordinate(polygon.coordinate)
        
        return MKMetersBetweenMapPoints(p1, p2)
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
    
    fileprivate var centerCoordinate: CLLocationCoordinate2D {
        get {
            guard self.points.count > 1 else {
                if let point = self.points.first {
                    return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
                }
                
                return kCLLocationCoordinate2DInvalid
            }
            
            guard let polygon = self.polygon else {
                return kCLLocationCoordinate2DInvalid
            }
            
            return polygon.coordinate
        }
    }
    
    fileprivate func contains(coordinate: CLLocationCoordinate2D) -> Bool {
        guard let polygon = self.polygon else {
            return false
        }
        
        let mapPoint = MKMapPointForCoordinate(coordinate)
        
        guard MKMapRectContainsPoint(polygon.boundingMapRect, mapPoint) else {
            return false
        }
        
        // Count the number of crossings to determine if inside (so-called ray-casting)
        var lastPoint = self.points.last!
        var isInside = false
        let x = coordinate.longitude
        
        self.points.forEach { point in
            var x1 = lastPoint.longitude
            var x2 = point.longitude
            var dx = x2 - x1
            
            if abs(dx) > 180.0 {
                // Likely around the 180th meridian, normalise (this app will likely never hit this code)
                if x > 0 {
                    while x1 < 0 {
                        x1 += 360.0
                    }
                    while x2 < 0 {
                        x2 += 360.0
                    }
                } else {
                    while x1 > 0 {
                        x1 -= 360.0
                    }
                    while x2 > 0 {
                        x2 -= 360.0
                    }
                }
                
                dx = x2 - x1
            }
            
            if (x1 <= x && x2 > x) || (x1 >= x && x2 < x) {
                let grad = (coordinate.latitude - lastPoint.latitude) / dx
                let intersectAtLat = lastPoint.latitude + ((x - x1) * grad)
                
                if intersectAtLat > coordinate.latitude {
                    isInside = !isInside
                }
            }
            
            lastPoint = point
        }
        
        return isInside
    }
}
