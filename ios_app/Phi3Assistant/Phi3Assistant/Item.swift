//
//  Item.swift
//  Phi3Assistant
//
//  Created by Guy Bonnen on 09/11/2025.
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
