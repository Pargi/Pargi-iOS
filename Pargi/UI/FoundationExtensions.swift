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

extension Array {
    func shift(withDistance distance: Int = 1) -> Array<Element> {
        let offsetIndex = distance >= 0 ?
            self.index(startIndex, offsetBy: distance, limitedBy: endIndex) :
            self.index(endIndex, offsetBy: distance, limitedBy: startIndex)
        
        guard let index = offsetIndex else { return self }
        return Array(self[index ..< endIndex] + self[startIndex ..< index])
    }
    
    mutating func shiftInPlace(withDistance distance: Int = 1) {
        self = shift(withDistance: distance)
    }
}

extension URL {
    static var endParkingPhoneNumber: URL {
        get {
            return URL(string: "tel://1903")!
        }
    }
}
