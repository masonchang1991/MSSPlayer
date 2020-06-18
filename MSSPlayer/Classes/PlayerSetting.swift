//
//  PlayerSetting.swift
//  FBSnapshotTestCase
//
//  Created by Mason on 2020/6/18.
//

import Foundation

public protocol PlayerSetting {
    var fastForwardSpeed: Double { get set }
    var voiceAdjustSpeed: Double { get set }
    var brightnessAdjustSpeed: Double { get set }
}

open class MSSPlayerSetting: PlayerSetting {
    public var fastForwardSpeed: Double = 1.0
    public var voiceAdjustSpeed: Double = 1.0
    public var brightnessAdjustSpeed: Double = 1.0
}
