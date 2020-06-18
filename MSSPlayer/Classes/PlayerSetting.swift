//
//  PlayerSetting.swift
//  FBSnapshotTestCase
//
//  Created by Mason on 2020/6/18.
//

import Foundation

public protocol PlayerSetting {
    var voiceAdjustSpeed: Double { get set }
    var brightnessAdjustSpeed: Double { get set }
}

open class MSSPlayerSetting: PlayerSetting {
    public var voiceAdjustSpeed: Double = 1.0
    public var brightnessAdjustSpeed: Double = 1.0
}
