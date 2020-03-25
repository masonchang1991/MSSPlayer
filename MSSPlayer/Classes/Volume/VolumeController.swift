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
    func setOnView(_ view: UIView)
    func changeToFullScreenMode(_ isFullScreen: Bool)
}

open class MSSPlayerVolumeController: VolumeController {
    
    // UI
    open var volumeView: VolumeView = SystemVolumeView()
    open lazy var landscapeVolumeView: VolumeView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 50))
        return NormalVolume(frame: frame)
    }()
    // Parameters
    open var isEnable: Bool = true
    open var timer: Timer?
    open var isFullScreen: Bool = false
    
    // MARK: - UI Display methods
    /// show volumeView with animation
    open func show() {
        resetTimer()
        if isFullScreen {
            landscapeVolumeView.show(animated: true)
        } else {
            volumeView.show(animated: true)
        }
    }
    /// dissappear volumeView with animation
    open func dissappear() {
        landscapeVolumeView.disappear(animated: true)
        volumeView.disappear(animated: true)
        removeTimer()
    }
    
    // MARK: - Open methods
    
    open func addVolume(_ value: Float) {
        if isFullScreen {
            updateVolume(landscapeVolumeView.getCurrentVolumeLevel() + value)
        } else {
            updateVolume(volumeView.getCurrentVolumeLevel() + value)
        }
    }
    
    open func updateVolume(_ level: Float) {
        if isEnable {
            show()
            if isFullScreen {
                landscapeVolumeView.updateVolumeLevelWith(level)
            } else {
                volumeView.updateVolumeLevelWith(level)
            }
        }
    }
    
    open func setOnView(_ view: UIView) {
        if isFullScreen {
            landscapeVolumeView.removeMPVolumeViewFromSuperView()
            landscapeVolumeView.setOnView(view)
        }
    }
    
    open func changeToFullScreenMode(_ isFullScreen: Bool) {
        self.isFullScreen = isFullScreen
        if !isFullScreen {
            landscapeVolumeView.removeMPVolumeViewFromSuperView()
        }
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
