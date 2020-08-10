//
//  MSSAsset.swift
//  MPlayer
//
//  Created by Mason on 2020/1/15.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public enum MSSAsset: String {
    case mss_play
    case mss_pause
    case mss_sliderThumb
    case mss_fullScreen
    case mss_endFullScreen
    case mss_seek
    case mss_playNext
    case mss_replay
    case mss_brightness
    case mss_volume_on
    case mss_volume_off
    case mss_brightness_on
}

open class MSSImageResource {
    
    static public func get(_ asset: MSSAsset) -> UIImage? {
        let frameworkBundle = Bundle(for: MSSImageResource.self)
        let bundleURL = frameworkBundle.resourceURL?.appendingPathComponent("MSSPlayer.bundle")
        let resourceBundle = Bundle(url: bundleURL!)
        let image = UIImage(named: asset.rawValue, in: resourceBundle, compatibleWith: nil)
        return image?.withRenderingMode(.alwaysOriginal)
    }
}
