//
//  AnnotationView.swift
//  Pargi
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class AnnotationView: MKAnnotationView {

    override public init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        self.initialise()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialise()
    }
    
    fileprivate func initialise() {
        self.backgroundColor = .clear
    }
    
    override var annotation: MKAnnotation? {
        didSet {
            self.frame.size = self.layoutBoundingRect().size
            self.centerOffset.y = self.bounds.midY - self.iconBoundingRect().midY
        }
    }
    
    // MARK: Helpers
    
    private func titleTextFont() -> UIFont {
        return UIFont.systemFont(ofSize: 10.0, weight: UIFontWeightHeavy)
    }
    
    private func textBoundingRect() -> CGRect {
        var frame = CGRect.zero
        
        if let title = self.annotation?.title as? String {
            let attributedTitle = NSAttributedString(string: title, attributes: [
                NSFontAttributeName: self.titleTextFont(),
                NSStrokeWidthAttributeName: -20.0,
                NSKernAttributeName: self.contentScaleFactor * 0.3])
            
            frame = CGRect(origin: .zero, size: attributedTitle.size())
            frame.size.height += 4.0
            frame.size.width += 4.0
        }
        
        return frame
    }
    
    private func iconBoundingRect() -> CGRect {
        return CGRect(origin: .zero, size: CGSize(width: 16.0, height: 16.0))
    }
    
    private func layoutBoundingRect() -> CGRect {
        let textRect = textBoundingRect()
        let iconRect = iconBoundingRect()
        
        return CGRect(origin: .zero, size: CGSize(width: max(textRect.width, iconRect.width), height: iconRect.height + textRect.height))
    }
    
    // MARK: Drawing
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let ctx = UIGraphicsGetCurrentContext()
        var textRect = self.textBoundingRect()
        var iconRect = self.iconBoundingRect()
        
        // Adjust frames to properly lay items out
        textRect = textRect.offsetBy(dx: (self.bounds.width - textRect.width) / 2.0 + 1.0, dy: self.bounds.height - textRect.height).insetBy(dx: 2.0, dy: 2.0)
        iconRect = iconRect.offsetBy(dx: (self.bounds.width - iconRect.width) / 2.0, dy: 2.0).insetBy(dx: 2.0, dy: 2.0)
        
        // Text attributes
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.alignment = .center

        var attributes: [String: Any] = [
            NSFontAttributeName: self.titleTextFont(),
            NSForegroundColorAttributeName: UIColor.white,
            NSKernAttributeName: self.contentScaleFactor * 0.3,
            NSParagraphStyleAttributeName: titleParagraphStyle
        ]
        
        // Draw icon
        ctx?.setLineWidth(2.0)
        ctx?.setLineJoin(.round)
        ctx?.setLineCap(.round)
        ctx?.setFillColor(self.tintColor.cgColor)
        ctx?.setStrokeColor(UIColor.white.cgColor)
        ctx?.strokeEllipse(in: iconRect)
        ctx?.fillEllipse(in: iconRect)
        
        ctx?.setTextDrawingMode(.fill)
        ("P" as NSString).draw(in: iconRect.offsetBy(dx: 0.5, dy: 0.0), withAttributes: attributes)
        
        guard let title = self.annotation?.title as? NSString else {
            return
        }
        
        // Draw outline first, then text
        ctx?.setTextDrawingMode(.fillStroke)
        title.draw(in: textRect.offsetBy(dx: 0.0, dy: 0.3), withAttributes: attributes)
        
        ctx?.setTextDrawingMode(.fill)
        attributes[NSForegroundColorAttributeName] = self.tintColor
        title.draw(in: textRect, withAttributes: attributes)
    }
}
