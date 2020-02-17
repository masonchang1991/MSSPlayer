//
//  MSSPlayerUtility.swift
//  MSSPlayer
//
//  Created by Mason on 2020/1/15.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation

class MSSPlayerUtility {
    static func formatSecondsToString(_ seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        } else {
            let min = Int(floor(seconds) / 60)
            let sec = Int(floor(seconds).truncatingRemainder(dividingBy: 60))
            return String(format: "%02d:%02d", min, sec)
        }
    }
}
