//
//  BrightnessController.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol BrightnessController {
    var isEnable: Bool { get set }
    var brightnessView: BrightnessView { get set }
    var timer: Timer? { get set }
    
    // UI Display methods
    func show()
    func dissappear()
    // Open methods
    func addBrightness(_ level: CGFloat)
    func updateBrightness(_ level: CGFloat)
}

open class MSSPlayerBrightnessController: BrightnessController {
    
    open var isEnable: Bool = false
    open var brightnessView: BrightnessView = MSSPlayerBrightnessView()
    open var timer: Timer?
    
    // MARK: - UI Display methods
    
    open func show() {
        if isEnable {
            resetTimer()
            brightnessView.show(animated: true)
        }
    }
    
    open func dissappear() {
        if isEnable {
            brightnessView.disappear(animated: true)
            removeTimer()
        }
    }
    
    // MARK: - Open methods
    
    open func addBrightness(_ level: CGFloat) {
        updateBrightness(brightnessView.getCurrentBrightnessLevel() + level)
    }
    
    open func updateBrightness(_ level: CGFloat) {
        show()
        brightnessView.updateBrightnessLevelWith(level)
    }
     
    @objc private func disappearBrightnessView() {
        dissappear()
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
        brightnessView.setNeedsLayout()
    }
    
    // MARK: - timer actions
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
                              selector: #selector(disappearBrightnessView),
                              userInfo: nil,
                              repeats: false)
            self.timer = timer
            RunLoop.main.add(timer,
                             forMode: RunLoop.Mode.default)
        }
    }
    
    // MARK: - initialization and deallocation
    
    public init() {
        addObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("BrightnessController dealloc")
    }
}
