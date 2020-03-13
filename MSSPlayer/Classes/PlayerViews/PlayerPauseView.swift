//
//  PlayerPauseView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol PlayerPauseViewDelegate: class {
    func pauseView(_ pauseView: PlayerPauseView, isPlay: Bool)
}

public protocol PlayerPauseView: UIView, PlayerControllerListener {
    var delegate: PlayerPauseViewDelegate? { get set }
    func show()
    func hide()
}

open class MSSPlayerPauseView: UIView, PlayerPauseView {
    
    // MARK: - UI Components
    open var mainMaskView: UIView = UIView()
    open var playBtnImageView: UIImageView = UIImageView()
    
    // MARK: - Parameters
    open weak var delegate: PlayerPauseViewDelegate?
    
    // MARK: - Open methods - UI Display
    open func show() {
        isHidden = false
    }
    
    open func hide() {
        isHidden = true
    }
    
    open func playStateDidChangeTo(playing: Bool) {
        playing ? hide(): show()
    }
    
    // MARK: - hitTest
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // hidden 的話 選擇不要接受事件，事件傳遞給下面
        if isHidden { return nil }
        
        // MARK: - 判斷是否點擊範圍在 target view 上，若不在上面則選擇不接收這個點擊事件
        let pointRelateToPlayBtnImageView = self.convert(point, to: playBtnImageView)
        if playBtnImageView.point(inside: pointRelateToPlayBtnImageView, with: event) {
            return playBtnImageView
        } else {
            return nil
        }
    }
    
    // MARK: - Private methods
    
    @objc private func tapPlay() {
        delegate?.pauseView(self, isPlay: true)
    }
    
    // MARK: - View Settings
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        playBtnImageView.frame = CGRect(origin: .zero,
                                        size: CGSize(width: 40,
                                                     height: 40))
        playBtnImageView.center = mainMaskView.center
    }
    
    open func addSubviews() {
        addSubview(mainMaskView)
        mainMaskView.addSubview(playBtnImageView)
    }
    
    open func setViewConstraints() {
        mainMaskView.frame = bounds
        mainMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    open func setViewSettings() {
        playBtnImageView.image = MSSImageResource.get(.mss_play)
        playBtnImageView.isUserInteractionEnabled = true
        playBtnImageView.contentMode = .scaleAspectFill
        playBtnImageView.clipsToBounds = true
    }
    
    open func setViewActions() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapPlay))
        playBtnImageView.addGestureRecognizer(tap)
    }
    
    // MARK: - Initialization and deallocation
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        setViewConstraints()
        setViewSettings()
        setViewActions()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubviews()
        setViewConstraints()
        setViewSettings()
        setViewActions()
    }
    
}
