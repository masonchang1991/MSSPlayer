//
//  VolumeView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit
import MediaPlayer

public protocol VolumeView: UIView {
    // UI Display methods
    func show(animated: Bool)
    func disappear(animated: Bool)
    // Open methods
    func getCurrentVolumeLevel() -> Float
    func updateVolumeLevelWith(_ volumeLevel: Float)
    func setOnView(_ view: UIView)
    func removeMPVolumeViewFromSuperView()
}

open class SystemVolumeView: UIView, VolumeView {
    
    private var volumeSlider: UISlider?
    
    // MARK: - UI Display methods
    
    open func show(animated: Bool) {
        // System don't need to show
    }
    
    open func disappear(animated: Bool) {
        // System don't need to disappear
    }
    
    // MARK: - Open methods
    
    open func getCurrentVolumeLevel() -> Float {
        guard let slider = volumeSlider else { return .zero }
        return slider.value
    }
    
    open func updateVolumeLevelWith(_ volumeLevel: Float) {
        guard let slider = volumeSlider else { return }
        slider.value = volumeLevel
    }
    
    open func setOnView(_ view: UIView) {
        
    }
    
    open func removeMPVolumeViewFromSuperView() {
        
    }
    
    // MARK: - initialization and deallocation
    
    convenience public init() {
        self.init(frame: .zero)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        let mpVolumeView = MPVolumeView(frame: .zero)
        self.volumeSlider = mpVolumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

open class NormalVolume: UIView, VolumeView {
    
    // MARK: - UIComponents
    private var volumeSlider: UISlider?
    let volumeView: MPVolumeView!
    let soundImageView: UIImageView = UIImageView()
    var containerView: UIView?
    
    
    // MARK: - Parameters
    private let edgeInset: UIEdgeInsets = UIEdgeInsets(top: 20, left: 50, bottom: 20, right: 20)
    private(set) var isShowing: Bool = false
    private var presentItem: DispatchWorkItem?
    
    open func setOnView(_ view: UIView) {
        self.frame = CGRect(x: edgeInset.left,
                            y: edgeInset.top, width: view.frame.width - edgeInset.left - edgeInset.right,
                            height: 30)
        self.containerView = view
        self.containerView?.addSubview(self)
        self.addSubview(self.volumeView)
        self.alpha = 0.001
        self.volumeView.frame = self.bounds
        self.volumeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    open func show(animated: Bool) {
        cancelCurrentPresentAction()
        presentItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            if animated {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    guard let self = self else { return }
                    self.alpha = 1.0
                }) { [weak self](isFinish) in
                    guard let self = self else { return }
                    if isFinish {
                        self.isShowing = true
                    }
                }
            } else {
                self.alpha = 1.0
                self.isShowing = true
            }
        })
        if let item = presentItem {
            DispatchQueue.main.async(execute: item)
        }
    }
    
    open func disappear(animated: Bool) {
        cancelCurrentPresentAction()
        presentItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            if animated {
                UIView.animate(withDuration: 0.2, animations: { [weak self] in
                    guard let self = self else { return }
                    self.alpha = 0.001
                }) { [weak self](isFinish) in
                    guard let self = self else { return }
                    if isFinish {
                        self.isShowing = false
                    }
                }
            } else {
                self.alpha = 0.01
                self.isShowing = false
            }
        })
        if let item = presentItem {
            DispatchQueue.main.async(execute: item)
        }
    }
    
    open func getCurrentVolumeLevel() -> Float {
        guard let slider = volumeSlider else { return .zero }
        return slider.value
    }
    
    open func updateVolumeLevelWith(_ volumeLevel: Float) {
        var level = volumeLevel
        if volumeLevel > 1 {
            level = 1
        } else if volumeLevel < 0 {
            level = 0
        }
        volumeSlider?.value = level
        
        if level > 0 {
            soundImageView.image = MSSImageResource.get(.mss_volume_on)?.withRenderingMode(.alwaysTemplate)
            soundImageView.tintColor = UIColor.white
        } else {
            soundImageView.image = MSSImageResource.get(.mss_volume_off)?.withRenderingMode(.alwaysTemplate)
            soundImageView.tintColor = UIColor.white
        }
    }
    
    open func removeMPVolumeViewFromSuperView() {
        volumeView.removeFromSuperview()
        self.removeFromSuperview()
    }
    
    // MARK: - Private methods
    
    private func cancelCurrentPresentAction() {
        guard let presentItem = presentItem else { return }
        presentItem.cancel()
    }
    
    // MARK: - View setting methods
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        soundImageView.frame = CGRect(origin: CGPoint(x: 0, y: 2),
                                      size: CGSize(width: self.frame.height / 2,
                                                   height: self.frame.height / 2))
        volumeView.frame = CGRect(x: soundImageView.frame.width + 5,
                                  y: 0,
                                  width: self.frame.width - (soundImageView.frame.width + 5),
                                  height: self.frame.height)
        volumeView.layer.cornerRadius = volumeView.frame.height / 2
    }
    
    func setupUI(){
        backgroundColor = .clear
        addSubview(volumeView)
        volumeView.frame = bounds
        volumeView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        volumeView.setVolumeThumbImage(UIImage(), for: UIControl.State())
        volumeView.isUserInteractionEnabled = false
        volumeView.alpha = 1.0
        volumeView.showsRouteButton = false
        volumeView.tintColor = UIColor.white.withAlphaComponent(0.4)
        
        addSubview(soundImageView)
        soundImageView.image = MSSImageResource.get(.mss_volume_on)?.withRenderingMode(.alwaysTemplate)
        soundImageView.contentMode = .scaleAspectFill
        soundImageView.clipsToBounds = true
        soundImageView.backgroundColor = .clear
        soundImageView.tintColor = UIColor.white
    }
    
    convenience public init() {
        self.init(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 30)))
    }
    
    override public init(frame: CGRect) {
        self.volumeView = MPVolumeView(frame: frame)
        super.init(frame: frame)
        self.volumeSlider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
