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
