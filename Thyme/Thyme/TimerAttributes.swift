//
//  TimerAttributes.swift
//  Thyme
//
//  Created by Zane Sabbagh on 3/30/24.
//

import Foundation
import ActivityKit
import SwiftUI

struct TimerAttributes: ActivityAttributes {
    public typealias TimerStatus = ContentState
    
    public struct ContentState: Codable, Hashable {
        var endTime: Date
    }
    var timerName: String
}
