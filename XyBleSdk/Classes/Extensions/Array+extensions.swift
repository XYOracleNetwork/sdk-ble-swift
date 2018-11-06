//
//  Array+extensions.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension String {
    var shortId: String {
        guard self.count > 0 else { return "" }
        let index = self.index(self.endIndex, offsetBy: -10)
        return String(self[index...])
    }
}
