//
//  UIKitExtensions.swift
//  Pargi
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import UIKit

extension UIButton {
    func update(withCallToAction cta: String, andDetail detail: String? = nil) {
        // Background
        self.setBackgroundImage(UIImage.roundedImage(cornerRadius: 8.0, lineWidth: 2.0, fill: false), for: .normal)
        self.setBackgroundImage(UIImage.roundedImage(cornerRadius: 8.0, lineWidth: 2.0, fill: true), for: .highlighted)
        
        // Text
        let font = UIFont.systemFont(ofSize: 14.0, weight: .heavy)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        var attributes: [NSAttributedStringKey: Any] = [.font: font, .paragraphStyle: paragraph, .foregroundColor: self.tintColor]
        let buttonTitle = NSMutableAttributedString(string: cta, attributes: attributes)
        
        if let detail = detail {
            attributes[NSAttributedStringKey.font] = UIFont.systemFont(ofSize: 10.0, weight: .regular)
            let detailTitle = NSAttributedString(string: "\n\(detail)", attributes: attributes)
            buttonTitle.append(detailTitle)
        }
        
        self.titleLabel?.numberOfLines = 0
        self.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .normal)
        
        buttonTitle.addAttributes([.foregroundColor: UIColor.white], range: NSRange(location: 0, length: buttonTitle.length))
        self.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .highlighted)
        
        buttonTitle.addAttributes([.foregroundColor: self.tintColor.withAlphaComponent(0.6) as Any], range: NSRange(location: 0, length: buttonTitle.length))
        self.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .disabled)
    }
    
    func update(withSecondaryCallToAction cta: String) {
        // Background
        self.setBackgroundImage(UIImage.roundedImage(cornerRadius: 8.0, lineWidth: 2.0, fill: true), for: .normal)
        self.adjustsImageWhenHighlighted = true
        
        // Text
        let font = UIFont.systemFont(ofSize: 12.0, weight: .semibold)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let attributes: [NSAttributedStringKey: Any] = [.font: font, .paragraphStyle: paragraph, .foregroundColor: UIColor.white]
        let buttonTitle = NSMutableAttributedString(string: cta, attributes: attributes)
        
        self.titleLabel?.numberOfLines = 1
        self.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .normal)
        
        buttonTitle.addAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.6) as Any], range: NSRange(location: 0, length: buttonTitle.length))
        self.setAttributedTitle(buttonTitle.copy() as? NSAttributedString, for: .disabled)
    }
}

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        
        var rgbValue: UInt64 = 0
        
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
    
    var hexString: String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        return String(
            format: "%02X%02X%02X",
            Int(r * 0xff),
            Int(g * 0xff),
            Int(b * 0xff)
        )
    }
}

extension String {
    func attributedCaption() -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.25
        
        let attributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.medium),
            .foregroundColor: UIColor(hex: "1C3244"),
            .paragraphStyle: paragraph
        ]
        
        return NSAttributedString(string: self, attributes: attributes)
    }
}

extension NSAttributedString {
    convenience init?(html: String) {
        guard let data = html.data(using: String.Encoding.utf16, allowLossyConversion: false) else {
            return nil
        }
        
        guard let attributedString = try? NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) else {
            return nil
        }
        
        self.init(attributedString: attributedString)
    }
}

extension UIImage {
    ///
    /// Create a template image of a rounded stroked rect, which is optionally filled
    ///
    class func roundedImage(cornerRadius: CGFloat, lineWidth: CGFloat, fill: Bool) -> UIImage {
        let size = CGSize(width: cornerRadius * 2 + 1.0 + lineWidth, height: cornerRadius * 2 + 1.0 + lineWidth)
        let rect = CGRect(origin: CGPoint.zero, size: size).insetBy(dx: lineWidth / 2.0, dy: lineWidth / 2.0)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        let ctx = UIGraphicsGetCurrentContext()
        let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        
        ctx?.setStrokeColor(UIColor.black.cgColor)
        ctx?.setFillColor(UIColor.black.cgColor)
        ctx?.setLineWidth(lineWidth)
        
        ctx?.addPath(path)
        ctx?.strokePath()
        
        if fill {
            ctx?.addPath(path)
            ctx?.fillPath()
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    
        let edge = cornerRadius + lineWidth
        return image!.resizableImage(withCapInsets: UIEdgeInsets(top: edge, left: edge, bottom: edge, right: edge), resizingMode: .tile).withRenderingMode(.alwaysTemplate)
    }
}
