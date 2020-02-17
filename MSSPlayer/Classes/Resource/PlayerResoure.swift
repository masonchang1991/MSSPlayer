//
//  PlayerResoure.swift
//  MPlayer
//
//  Created by Mason on 2020/1/8.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import AVFoundation

public protocol PlayerResource {
    var resourceKey: String { get }
    var playerItem: AVPlayerItem { get }
}

public class MSSPlayerResource: PlayerResource {
    
    public var resourceKey: String
    public var playerItem: AVPlayerItem
    
    convenience public init(_ url: URL) {
        let asset = AVURLAsset(url: url)
        self.init(asset)
    }
    
    convenience public init(_ asset: AVURLAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        self.init(playerItem)
    }
    
    public init(_ item: AVPlayerItem) {
        self.resourceKey = (item.asset as! AVURLAsset).url.absoluteString
        self.playerItem = item
    }
}
