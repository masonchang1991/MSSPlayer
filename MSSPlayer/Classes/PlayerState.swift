//
//  PlayerState.swift
//  MPlayer
//
//  Created by Mason on 2020/1/9.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation

public enum PlayerState: Equatable {
    
    case empty
    case initial
    case playing
    case pause
    case readyToPlay
    case buffering
    case bufferFinished
    case playedToTheEnd
    case error(Error?)
    
    public static func ==(lhs: PlayerState, rhs: PlayerState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case (.initial, .initial):
            return true
        case (.playing, .playing):
            return true
        case (.pause, .pause):
            return true
        case (.readyToPlay, .readyToPlay):
            return true
        case (.buffering, .buffering):
            return true
        case (.bufferFinished, .bufferFinished):
            return true
        case (.playedToTheEnd, .playedToTheEnd):
            return true
        case (.error(_), .error(_)):
            return true
        default: return false
        }
    }
}
