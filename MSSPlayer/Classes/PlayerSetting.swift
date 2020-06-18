//
//  PlayerSetting.swift
//  FBSnapshotTestCase
//
//  Created by Mason on 2020/6/18.
//

import Foundation

public protocol PlayerSetting {
    var fastForwardSpeed: Float { get set }
    var voiceAdjustSpeed: Float { get set }
    var brightnessAdjustSpeed: Float { get set }
}

open class MSSPlayerSetting: PlayerSetting {
    public var fastForwardSpeed: Float = 1.0
    public var voiceAdjustSpeed: Float = 1.0
    public var brightnessAdjustSpeed: Float = 1.0
}
