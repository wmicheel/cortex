//
//  Item.swift
//  cortex
//
//  Created by Wieland Micheel on 13.11.25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
