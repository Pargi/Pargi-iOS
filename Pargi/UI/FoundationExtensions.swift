//
//  FoundationExtensions.swift
//  Pargi
//
//  Created by Henri Normak on 29/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation

extension String {
    func localized(withComment:String) -> String {
        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: withComment)
    }
}
