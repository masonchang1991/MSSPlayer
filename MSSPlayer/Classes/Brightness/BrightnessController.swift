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
    func changeOrientation(_ orientation: UIDeviceOrientation)
    func setOnView(_ view: UIView)
    func changeToFullScreenMode(_ isFullScreen: Bool)
}

open class MSSPlayerBrightnessController: BrightnessController {
    
    open var isEnable: Bool = true
    open var brightnessView: BrightnessView = MSSPlayerBrightnessView()
    open lazy var landscapeBrightnessView: BrightnessView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: 300, height: 50))
        return NormalBrightness(frame: frame)
    }()
    open var timer: Timer?
    open var isFullScreen: Bool = false
    
    // MARK: - UI Display methods
    
    open func show() {
        resetTimer()
        if isFullScreen {
            landscapeBrightnessView.show(animated: true)
        } else {
            brightnessView.show(animated: true)
        }
    }
    
    open func dissappear() {
        landscapeBrightnessView.disappear(animated: true)
        brightnessView.disappear(animated: true)
        removeTimer()
    }
    
    // MARK: - Open methods
    
    open func addBrightness(_ level: CGFloat) {
        if isFullScreen {
            updateBrightness(landscapeBrightnessView.getCurrentBrightnessLevel() + level)
        } else {
            updateBrightness(brightnessView.getCurrentBrightnessLevel() + level)
        }
    }
    
    open func updateBrightness(_ level: CGFloat) {
        if isEnable {
            show()
            if isFullScreen {
                landscapeBrightnessView.updateBrightnessLevelWith(level)
            } else {
                brightnessView.updateBrightnessLevelWith(level)
            }
        }
    }
    
    open func setOnView(_ view: UIView) {
        if isFullScreen {
            landscapeBrightnessView.removeBrightnessViewFromSuperView()
            landscapeBrightnessView.setOnView(view)
        }
    }
    
    open func changeToFullScreenMode(_ isFullScreen: Bool) {
        self.isFullScreen = isFullScreen
        if !isFullScreen {
            landscapeBrightnessView.removeBrightnessViewFromSuperView()
        }
    }
     
    @objc private func disappearBrightnessView() {
        dissappear()
    }
    
    open func changeOrientation(_ orientation: UIDeviceOrientation) {
        brightnessView.transform = getRotationTransformBy(orientation)
    }
    
    // MARK: - Private methods
    
    private func getRotationTransformBy(_ orientation: UIDeviceOrientation) -> CGAffineTransform {
        switch orientation {
        case .portrait: return .identity
        case .landscapeLeft: return CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .landscapeRight: return CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        case .portraitUpsideDown: return CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        default: return .identity
        }
    }
    
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
