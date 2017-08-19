//
//  MessageUIExtensions.swift
//  Pargi
//
//  Created by Henri Normak on 18/08/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import MessageUI

extension MFMessageComposeViewController {
    ///
    /// Convenience initialiser for creating a SMS composer that can be used to start parking
    ///
    /// - parameters:
    ///     - licensePlate: License plate number to use in the SMS
    ///     - zone: Zone to use in the SMS (zone.code is used)
    ///
    convenience init(licensePlate: String, zone: Zone) {
        self.init()
        self.disableUserAttachments()
        
        self.body = "\(licensePlate) \(zone.code)"
        self.recipients = ["1902"]
    }
}
