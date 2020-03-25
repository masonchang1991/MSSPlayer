//
//  PlayerPresenter.swift
//  MPlayer
//
//  Created by Mason on 2020/1/30.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public enum PresentMode {
    case landScapeRightFullScreen
    case landScapeLeftFullScreen
    case portraitFullScreen
    case portrait
}

public protocol PlayerPresenterDelegate: class {
    func playerPresenter(_ presenter: PlayerPresenter, orientationDidChanged orientation: UIDeviceOrientation)
    func playerPresenter(_ presenter: PlayerPresenter, modeWillChanged Mode: PresentMode)
    func playerPresenter(_ presenter: PlayerPresenter, modeDidChanged Mode: PresentMode)
}

public protocol PlayerPresenter {
    //MARK: - UI Components
    var fullScreenContainerView: UIView? { get set }
    var portraitContainerView: UIView? { get set }
    
    // MARK: - Parameters
    var currentMode: PresentMode { get }
    var isPortraitFullScreen: Bool { get set }
    var delegate: PlayerPresenterDelegate? { get set }
    
    // MARK: - Open methods
    func replaceContainerView(_ view: UIView?, mode: PresentMode)
    func changeToFullScreen(_ isFullScreen: Bool, playerView: UIView, animated: Bool)
    func changeMode(_ mode: PresentMode, playerView: UIView, animated: Bool)
    func setMode(_ mode: PresentMode, playerView: UIView, animated: Bool)
}

open class MSSPlayerPresenter: PlayerPresenter, Loggable {
    
    // MARK: - UI Components
    /// fullScreenContainerView use key window as default
    open lazy var fullScreenContainerView: UIView? = UIApplication.sceneKeyWindow
    open var portraitContainerView: UIView?
    
    // MARK: - Parameters
    
    open private(set) var currentMode: PresentMode = .portrait {
        willSet {
            if newValue != currentMode {
                delegate?.playerPresenter(self, modeWillChanged: currentMode)
            }
        }
        didSet {
            if oldValue != currentMode {
                delegate?.playerPresenter(self, modeDidChanged: currentMode)
            }
        }
    }
    open var isPortraitFullScreen: Bool = false
    
    // Delegates
    open var delegate: PlayerPresenterDelegate?
    
    // Private Parameters
    /// get current device interfaceOrientation
    var deviceOrientation: UIDeviceOrientation {
        return UIDevice.current.orientation
    }
    
    // MARK: - Open method
    
    open func replaceContainerView(_ view: UIView?, mode: PresentMode) {
        switch mode {
        case .landScapeRightFullScreen, .landScapeLeftFullScreen:
            fullScreenContainerView = view
        case .portraitFullScreen:
            fullScreenContainerView = view
        case .portrait:
            portraitContainerView = view
        }
    }
    
    open func changeToFullScreen(_ isFullScreen: Bool, playerView: UIView, animated: Bool) {
        if isFullScreen {
            if isPortraitFullScreen {
                changeMode(.portraitFullScreen, playerView: playerView, animated: animated)
            } else {
                switch deviceOrientation {
                case .landscapeLeft:
                    changeMode(.landScapeLeftFullScreen, playerView: playerView, animated: animated)
                case .landscapeRight:
                    changeMode(.landScapeRightFullScreen, playerView: playerView, animated: animated)
                default: break
                }
            }
        } else {
            changeMode(.portrait, playerView: playerView, animated: animated)
        }
    }
    
    open func changeMode(_ mode: PresentMode, playerView: UIView, animated: Bool) {
        if mode == currentMode { return }
        setMode(mode, playerView: playerView, animated: animated)
    }
    
    open func setMode(_ mode: PresentMode, playerView: UIView, animated: Bool) {
        switch mode {
        case .landScapeRightFullScreen, .landScapeLeftFullScreen:
            guard let fullScreenContainerView = fullScreenContainerView else { return }
            // 獲取 rotateView 相較於 fullScreenContainerView 的 frame
            // rotateView 在 addSubView 後會維持在同樣的位置
            playerView.frame = playerView.convert(playerView.frame, to: fullScreenContainerView)
            if animated {
                UIView.animate(withDuration: 0.3, animations: { [weak fullScreenContainerView, weak playerView] in
                    guard let fullScreenContainerView = fullScreenContainerView else { return }
                    guard let playerView = playerView else { return }
                    let orientation: UIInterfaceOrientation = mode == .landScapeRightFullScreen ? .landscapeRight : .landscapeLeft
                    playerView.transform = self.getRotationTransformBy(orientation)
                    UIView.animate(withDuration: 0.3) {
                        playerView.frame = fullScreenContainerView.frame
                        playerView.layoutIfNeeded()
                    }
                }) { [weak self, weak fullScreenContainerView, weak playerView](_) in
                    guard let self = self else { return }
                    guard let fullScreenContainerView = fullScreenContainerView else { return }
                    guard let playerView = playerView else { return }
                    playerView.removeFromSuperview()
                    fullScreenContainerView.addSubview(playerView)
                    playerView.frame = fullScreenContainerView.bounds
                    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.currentMode = mode
                }
            } else {
                playerView.removeFromSuperview()
                fullScreenContainerView.addSubview(playerView)
                playerView.frame = fullScreenContainerView.bounds
                playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                playerView.layoutIfNeeded()
                self.currentMode = mode
            }
        case .portraitFullScreen:
            guard let fullScreenContainerView = fullScreenContainerView else { return }
            
            if animated {
                // 設定 playerView 當前的 frame 為 fullScreenContainerView 的相對 frame
                // 當 addSubView 在 fullScreenContainerView 上時，此 frame 為目前位置
                playerView.frame = playerView.convert(playerView.frame, to: fullScreenContainerView)

                UIView.animate(withDuration: 0.3, animations: { [weak fullScreenContainerView, weak playerView] in
                    guard let fullScreenContainerView = fullScreenContainerView else { return }
                    guard let playerView = playerView else { return }
                    playerView.frame = fullScreenContainerView.frame
                    playerView.layoutIfNeeded()
                }) { [weak self, weak fullScreenContainerView, weak playerView](_) in
                    guard let self = self else { return }
                    guard let fullScreenContainerView = fullScreenContainerView else { return }
                    guard let playerView = playerView else { return }
                    playerView.removeFromSuperview()
                    fullScreenContainerView.addSubview(playerView)
                    playerView.frame = fullScreenContainerView.bounds
                    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.currentMode = .portraitFullScreen
                }
            } else {
                playerView.removeFromSuperview()
                fullScreenContainerView.addSubview(playerView)
                playerView.frame = fullScreenContainerView.bounds
                playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                playerView.layoutIfNeeded()
                self.currentMode = .portraitFullScreen
            }
        case .portrait:
            guard let portraitContainerView = portraitContainerView else { return }
            // 獲取 rotateView 相較於 fullScreenContainerView 的 frame
            // rotateView 在 addSubView 後會維持在同樣的位置
            
            if animated {
                // rotateView 在 addSubView 後會維持在同樣的位置
                let frame: CGRect
                switch currentMode {
                case .landScapeRightFullScreen, .landScapeLeftFullScreen, .portraitFullScreen:
                    frame = portraitContainerView.convert(portraitContainerView.bounds,
                                                          to: fullScreenContainerView)
                case .portrait:
                    frame = playerView.convert(playerView.bounds,
                                               to: portraitContainerView)
                }
                
                UIView.animate(withDuration: 0.3, animations: { [weak playerView] in
                    guard let playerView = playerView else { return }
                    playerView.transform = self.getRotationTransformBy(.portrait)
                    UIView.animate(withDuration: 0.3) {
                        playerView.frame = frame
                        playerView.layoutIfNeeded()
                    }
                }) { [weak self, weak portraitContainerView, weak playerView](_) in
                    guard let self = self else { return }
                    guard let portraitContainerView = portraitContainerView else { return }
                    guard let playerView = playerView else { return }
                    playerView.removeFromSuperview()
                    portraitContainerView.addSubview(playerView)
                    playerView.frame = portraitContainerView.bounds
                    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    self.currentMode = .portrait
                }
            } else {
                playerView.removeFromSuperview()
                portraitContainerView.addSubview(playerView)
                playerView.frame = portraitContainerView.bounds
                playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                playerView.layoutIfNeeded()
                self.currentMode = .portrait
            }
        }
    }
    
    open func updateInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
    
    // MARK: - Private methods
    
    private func addObservers() {
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self,
                               selector: #selector(onOrientationChanged),
                               name: UIDevice.orientationDidChangeNotification,
                               object: nil)
    }
    
    private func removeObservers() {
        let notiCenter = NotificationCenter.default
        notiCenter.removeObserver(self)
    }
    
    @objc private func onOrientationChanged() {
        delegate?.playerPresenter(self, orientationDidChanged: deviceOrientation)
    }
    
    private func getRotationTransformBy(_ orientation: UIInterfaceOrientation) -> CGAffineTransform {
        switch orientation {
        case .portrait: return .identity
        case .landscapeLeft: return CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        case .landscapeRight: return CGAffineTransform(rotationAngle: -CGFloat.pi / 2)
        case .portraitUpsideDown: return CGAffineTransform(rotationAngle: CGFloat.pi / 2)
        default: return .identity
        }
    }
    
    // MARK: - initialization and deallocation method
    
    public init() {
        addObservers()
    }
    
    private func prepareToDealloc() {
        removeObservers()
    }
    
    deinit {
        prepareToDealloc()
    }
}
