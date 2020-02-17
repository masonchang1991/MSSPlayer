//
//  VolumeController.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol VolumeController {
    // UI
    var volumeView: VolumeView { get set }
    
    // Parameters
    var isEnable: Bool { get set }
    var timer: Timer? { get set }
    
    // UI Display methods
    func show()
    func dissappear()
    
    // Open methods
    func addVolume(_ value: Float)
    func updateVolume(_ level: Float)
}

open class MSSPlayerVolumeController: VolumeController {
    
    // UI
    open var volumeView: VolumeView = SystemVolumeView()
    // Parameters
    open var isEnable: Bool = false
    open var timer: Timer?
    
    // MARK: - UI Display methods
    /// show volumeView with animation
    open func show() {
        if isEnable {
            resetTimer()
            volumeView.show(animated: true)
        }
    }
    /// dissappear volumeView with animation
    open func dissappear() {
        if isEnable {
            volumeView.disappear(animated: true)
            removeTimer()
        }
    }
    
    // MARK: - Open methods
    
    open func addVolume(_ value: Float) {
        updateVolume(volumeView.getCurrentVolumeLevel() + value)
    }
    
    open func updateVolume(_ level: Float) {
        show()
        volumeView.updateVolumeLevelWith(level)
    }
    
    // MARK: - Private methods
    
    private func addObservers() {
        let notiCenter = NotificationCenter.default
        if #available(iOS 13.0, *) {
            notiCenter.addObserver(self,
            selector: #selector(orientationNotification(_:)),
            name: UIDevice.orientationDidChangeNotification,
            object: nil)
        } else {
            notiCenter.addObserver(self,
            selector: #selector(orientationNotification(_:)),
            name: UIApplication.didChangeStatusBarOrientationNotification,
            object: nil)
        }
    }
    
    @objc private func orientationNotification(_ notification: NSNotification) {
        volumeView.setNeedsLayout()
    }
    
    @objc private func disappearVolumeView() {
        dissappear()
    }

    private func resetTimer() {
        removeTimer()
        addTimer()
    }
    
    private func removeTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func addTimer() {
        if timer == nil {
            let timer = Timer(timeInterval: 2,
                              target: self,
                              selector: #selector(disappearVolumeView),
                              userInfo: nil,
                              repeats: false)
            self.timer = timer
            RunLoop.main.add(timer,
                             forMode: RunLoop.Mode.default)
        }
    }
    
    // MARK: - Initialization and Deallocation
    
    public init() {
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("VolumeController dealloc")
    }
}
