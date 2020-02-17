//
//  PlayerSystemService.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation

public struct PlayerSystemService {
    
    static public var brightNessController: BrightnessController = MSSPlayerBrightnessController()
    static public var volumeController: VolumeController = MSSPlayerVolumeController()
    
    static public func getBrightnessController() -> BrightnessController {
        brightNessController.dissappear()
        return brightNessController
    }
    
    static public func getVolumeController() -> VolumeController {
        volumeController.dissappear()
        return volumeController
    }
}
