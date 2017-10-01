//
//  InfoViewController.swift
//  Pargi
//
//  Created by Henri Normak on 06/05/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController, UITextViewDelegate {

    @IBOutlet var symbolImageView: UIImageView!
    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var databaseVersionLabel: UILabel!
    @IBOutlet var acknowledgmentsTextView: UITextView!
    @IBOutlet var sourceCodeTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        
        // UIImageView is moody
        let image = self.symbolImageView.image
        self.symbolImageView.image = nil
        self.symbolImageView.image = image
        
        // Version
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            self.versionLabel.text = "UI.About.Version".localized(withComment: "Application version") + " " + version
        } else {
            self.versionLabel.text = ""
        }
        
        // DB version
        self.databaseVersionLabel.text = "UI.About.DatabaseVersion".localized(withComment: "Database version") + " " + ApplicationData.currentDatabase.version.rawValue
        
        // Acknowledgments
        let ackText = NSAttributedString(html: "UI.About.Acknowledgments.HTML".localized(withComment: "3rd party software acknowledgments"))?.mutableCopy() as! NSMutableAttributedString
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center

        let attributes: [NSAttributedStringKey: Any] = [
            .font: UIFont.systemFont(ofSize: 14.0, weight: UIFont.Weight.regular),
            .paragraphStyle: paragraph,
            .foregroundColor: UIColor(hex: "1C3244")
        ]
        ackText.addAttributes(attributes, range: NSRange(location: 0, length: ackText.length))
        
        self.acknowledgmentsTextView.attributedText = ackText
        
        // OSS
        let sourceCodeText = NSAttributedString(html: "UI.About.OSS.HTML".localized(withComment: "Source Code links"))?.mutableCopy() as! NSMutableAttributedString
        sourceCodeText.addAttributes(attributes, range: NSRange(location: 0, length: sourceCodeText.length))
        self.sourceCodeTextView.attributedText = sourceCodeText
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if !NSEqualRanges(textView.selectedRange, NSRange(location: 0, length: 0)) {
            textView.selectedRange = NSRange(location: 0, length: 0)
        }
    }
}
