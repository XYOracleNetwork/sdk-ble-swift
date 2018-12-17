//
//  Array+extensions.swift
//  XYBleSdk
//
//  Created by Darren Sutherland on 9/7/18.
//  Copyright © 2018 XY - The Findables Company. All rights reserved.
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
        var chunks = self.split(separator: ".")
        chunks.removeFirst()
        return chunks.joined(separator: ".")
    }
}
