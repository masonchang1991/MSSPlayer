//
//  PlayerControlView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/13.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol PlayerControlViewDelegate: class {
    /// Call when tap play btn
    func playerControlView(_ controlView: PlayerControlView, isPlaying: Bool)
    /// Call when tap fullscreen btn
    func playerControlView(_ controlView: PlayerControlView, isFullScreen: Bool)
    /// Call when controlView show state changed
    func playerControlView(_ controlView: PlayerControlView, willAppear animated: Bool)
    func playerControlView(_ controlView: PlayerControlView, didAppear animated: Bool)
    func playerControlView(_ controlView: PlayerControlView, willDisappear animated: Bool)
    func playerControlView(_ controlView: PlayerControlView, didDisappear animated: Bool)
    /**
     call when slider action trigged
     
     - parameter controlView: control view
     - parameter slider: progress slider
     - parameter event:  action
     */
    func playerControlView(_ controlView: PlayerControlView, slider: UISlider, onSlider event: UIControl.Event)
}

public protocol PlayerControlView: UIView, PlayerControllerListener {
    
    // MARK: - UI Components
    var playBtn: UIButton { get set }
    var fullScreenBtn: UIButton { get set }
    var timeProgressLabel: UILabel { get set }
    var timeSlider: UISlider { get set }
    var progressView: UIProgressView { get set }
    
    // MARK: - Parameters
    var isShowing: Bool { get }
    var delegate: PlayerControlViewDelegate? { get set }
    
    // MARK: - UI Display methods
    func showControlView(animated: Bool)
    func hideControlView(animated: Bool)
    func showErrorViewWith(_ message: String)
    func hideErrorView()
    func showSeekTo(_ seconds: TimeInterval, total duration: TimeInterval, isAdd: Bool)
    func hideSeekView()
    
    // MARK: - Update View methods
    func updateCurrentTime(_ current: TimeInterval, total: TimeInterval)
    func updatePlayState(isPlaying: Bool)
    func updateFullScrennState(isFullScreen: Bool)
    func updateLoadedTime(_ loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func resetControlView()
}

open class MSSPlayerPortraitControlView: UIView, PlayerControlView {
    
    // MARK: - UI Components
    open var playBtn: UIButton = UIButton(type: .custom)
    open var fullScreenBtn: UIButton = UIButton(type: .custom)
    open var timeProgressLabel: UILabel = UILabel()
    open var timeSlider: UISlider = MSSTimeSlider()
    open var progressView: UIProgressView = UIProgressView()
    
    open var mainMaskView: UIView = UIView()
    open var topMaskView: UIView = UIView()
    open var bottomMaskView: UIView = UIView()
    open var seekToView = UIView()
    open var seekToViewImage = UIImageView()
    open var seekToLabel = UILabel()
    open lazy var errorMsgLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()
    
    // MARK: - Parameters
    open var isShowing: Bool = false
    open var topMaskBarHeight: CGFloat = 37
    open var bottomMaskBarHeight: CGFloat = 40.0
    open var delayItem: DispatchWorkItem?
    
    // Notify
    open weak var delegate: PlayerControlViewDelegate?
    
    // MARK: - Open methods - View Display
    
    open func showControlView(animated: Bool = true) {
        controlViewAnimation(isShow: true, animated: animated)
    }
    
    open func hideControlView(animated: Bool = true) {
        controlViewAnimation(isShow: false, animated: animated)
    }
    
    open func controlViewAnimation(isShow: Bool, animated: Bool = true) {
        if isShow {
            delegate?.playerControlView(self, willAppear: animated)
        } else {
            delegate?.playerControlView(self, willDisappear: animated)
        }
        
        let otherAlpha: CGFloat = isShow ? 1.0 : 0.0
        let mainAlpha: CGFloat = isShow ? 0.3 : 0.0
        if animated {
            UIView.animate(withDuration: 0.3, animations: { [weak self] in
                self?.topMaskView.alpha = otherAlpha
                self?.bottomMaskView.alpha = otherAlpha
                
                self?.mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(mainAlpha)
                self?.layoutIfNeeded()
            }, completion: { [weak self](isFinished) in
                guard let self = self else { return }
                if isFinished {
                    self.isShowing = isShow
                    if isShow {
                        self.autoFadeOutControlViewWithAnimation()
                        self.delegate?.playerControlView(self, didAppear: animated)
                    } else {
                        self.delegate?.playerControlView(self, didDisappear: animated)
                    }
                }
            })
        } else {
            topMaskView.alpha = otherAlpha
            bottomMaskView.alpha = otherAlpha
            mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(mainAlpha)
            self.isShowing = isShow
            layoutIfNeeded()
            
            if isShow {
                self.delegate?.playerControlView(self, didAppear: animated)
            } else {
                self.delegate?.playerControlView(self, didDisappear: animated)
            }
        }
    }
    
    open func showErrorViewWith(_ message: String) {
        errorMsgLabel.text = message
        errorMsgLabel.isHidden = false
        layoutSubviews()
    }
    
    open func hideErrorView() {
        errorMsgLabel.isHidden = true
    }
    
    open func showSeekTo(_ seconds: TimeInterval, total duration: TimeInterval, isAdd: Bool) {
        seekToView.isHidden = false
        seekToLabel.text = MSSPlayerUtility.formatSecondsToString(seconds)
        
        let rotate = isAdd ? 0: CGFloat(Double.pi)
        seekToViewImage.transform = CGAffineTransform(rotationAngle: rotate)
        updateCurrentTime(seconds, total: duration)
    }
    
    open func hideSeekView() {
        seekToView.isHidden = true
    }
    
    // MARK: - Open methods - Update View
    
    open func resetControlView() {
        timeSlider.value = 0.0
        timeProgressLabel.text = "00:00/00:00"
        updatePlayState(isPlaying: false)
    }
    
    open func updateCurrentTime(_ current: TimeInterval, total: TimeInterval) {
        let targetTime = MSSPlayerUtility.formatSecondsToString(current)
        timeSlider.value = Float(current / total)
        timeProgressLabel.text = targetTime + "/" + MSSPlayerUtility.formatSecondsToString(total)
    }
    
    open func playStateDidChangeTo(playing: Bool) {
        updatePlayState(isPlaying: playing)
    }
    
    open func updatePlayState(isPlaying: Bool) {
        playBtn.isSelected = isPlaying
    }
    
    open func updateFullScrennState(isFullScreen: Bool) {
        fullScreenBtn.isSelected = isFullScreen
    }
    
    open func updateLoadedTime(_ loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        progressView.setProgress(Float(loadedDuration) / Float(totalDuration), animated: true)
    }
    
    // MARK: - handle Slider Actions
    
    @objc open func progressSliderTouchBegan(_ sender: UISlider) {
        delegate?.playerControlView(self, slider: sender, onSlider: .touchDown)
    }
    
    @objc open func progressSliderValueChanged(_ sender: UISlider) {
        delegate?.playerControlView(self, slider: sender, onSlider: .valueChanged)
    }
    
    @objc open func progressSliderTouchEnded(_ sender: UISlider) {
        delegate?.playerControlView(self, slider: sender, onSlider: .touchUpInside)
    }
    
    // MARK: - handle button actions
    @objc open func fullScreenBtnPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        delegate?.playerControlView(self, isFullScreen: sender.isSelected)
    }
    
    @objc open func playBtnPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        delegate?.playerControlView(self, isPlaying: sender.isSelected)
    }
    
    /**
     auto fade out controlView with animation
     */
    open func autoFadeOutControlViewWithAnimation() {
        cancelAutoFadeOutAnimation()
        delayItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.controlViewAnimation(isShow: false)
        }
        if let item = delayItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0,
                                          execute: item)
        }
    }
    
    /**
     cancel auto fade out controlView with animation
     */
    open func cancelAutoFadeOutAnimation() {
        guard let delayItem = delayItem else { return }
        delayItem.cancel()
    }
    
    // MARK: - private methods
    
    private func getTextSizeBy(_ text: String, font: UIFont) -> CGSize {
        let options: NSStringDrawingOptions = [.usesFontLeading, .usesLineFragmentOrigin]
        let attributes = [NSAttributedString.Key.font: font]
        let constrainedSize = CGSize(width: bounds.width - 40,
                                     height: CGFloat.greatestFiniteMagnitude)
        var bounds = (text as NSString).boundingRect(with: constrainedSize,
                                                     options: options,
                                                     attributes: attributes,
                                                     context: nil)
        bounds.size = CGSize(width: bounds.width, height: bounds.height + 20)
        return bounds.size
    }
    
    // MARK: - views setting
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        topMaskView.frame = CGRect(origin: .zero,
                                   size: CGSize(width: bounds.width,
                                                height: topMaskBarHeight))
        bottomMaskView.frame = CGRect(x: .zero,
                                      y: bounds.height - bottomMaskBarHeight,
                                      width: bounds.width,
                                      height: bottomMaskBarHeight)
        errorMsgLabel.frame = CGRect(origin: .zero,
                                     size: getTextSizeBy(errorMsgLabel.text ?? "",
                                                         font: errorMsgLabel.font))
        errorMsgLabel.center = center
    }
    
    open func addSubViews() {
        addSubview(mainMaskView)
        
        mainMaskView.addSubview(topMaskView)
        mainMaskView.addSubview(bottomMaskView)
        
        bottomMaskView.addSubview(playBtn)
        bottomMaskView.addSubview(progressView)
        bottomMaskView.addSubview(timeSlider)
        bottomMaskView.addSubview(timeProgressLabel)
        bottomMaskView.addSubview(fullScreenBtn)
        
        addSubview(seekToView)
        seekToView.addSubview(seekToViewImage)
        seekToView.addSubview(seekToLabel)
        
        addSubview(errorMsgLabel)
    }
    
    open func setViewSettings() {
        mainMaskView.clipsToBounds = true
        mainMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
        seekToView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        seekToView.layer.cornerRadius = 4
        seekToView.clipsToBounds = true
        seekToView.isHidden = true
        
        seekToViewImage.image = MSSImageResource.get(.mss_seek)
        
        seekToLabel.font = .systemFont(ofSize: 13)
        seekToLabel.adjustsFontSizeToFitWidth = true
        seekToLabel.textColor = UIColor(red: 0.9098, green: 0.9098, blue: 0.9098, alpha: 1.0)
        
        playBtn.setImage(MSSImageResource.get(.mss_play), for: .normal)
        playBtn.setImage(MSSImageResource.get(.mss_pause), for: .selected)
        
        timeProgressLabel.textColor = .white
        timeProgressLabel.font = UIFont(name: "PingFangSC-Medium", size: 10.0)
        timeProgressLabel.adjustsFontSizeToFitWidth = true
        timeProgressLabel.textAlignment = .center
        // Default text
        timeProgressLabel.text = "00:00/00:00"
        
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.value        = 0.0
        timeSlider.setThumbImage(MSSImageResource.get(.mss_sliderThumb), for: .normal)
        timeSlider.maximumTrackTintColor = UIColor.clear
        timeSlider.minimumTrackTintColor = UIColor.red
        
        progressView.tintColor = UIColor.white.withAlphaComponent(0.6)
        progressView.trackTintColor = UIColor.white.withAlphaComponent(0.3)
        
        fullScreenBtn.setImage(MSSImageResource.get(.mss_fullScreen), for: .normal)
        fullScreenBtn.setImage(MSSImageResource.get(.mss_endFullScreen), for: .selected)
    }
    
    open func setViewActions() {
        timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)), for: .touchDown)
        timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)), for: .valueChanged)
        timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)), for: [.touchDragExit,
                                                                                          .touchCancel,
                                                                                          .touchUpInside])
        playBtn.addTarget(self, action: #selector(playBtnPressed(_:)), for: .touchUpInside)
        fullScreenBtn.addTarget(self, action: #selector(fullScreenBtnPressed), for: .touchUpInside)
    }
    
    open func setViewConstraints() {
        mainMaskView.frame = bounds
        mainMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        topMaskView.frame = CGRect(origin: .zero,
                                   size: CGSize(width: bounds.width,
                                                height: topMaskBarHeight))
        bottomMaskView.frame = CGRect(x: .zero,
                                      y: bounds.height - bottomMaskBarHeight,
                                      width: bounds.width,
                                      height: bottomMaskBarHeight)
        
        playBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playBtn.leadingAnchor.constraint(equalTo: bottomMaskView.leadingAnchor, constant: 10.0),
            playBtn.topAnchor.constraint(equalTo: bottomMaskView.topAnchor, constant: 8),
            playBtn.bottomAnchor.constraint(equalTo: bottomMaskView.bottomAnchor, constant: -8),
            playBtn.widthAnchor.constraint(equalTo: playBtn.heightAnchor)
        ])
        
        timeSlider.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeSlider.centerYAnchor.constraint(equalTo: bottomMaskView.centerYAnchor),
            timeSlider.leadingAnchor.constraint(equalTo: playBtn.trailingAnchor, constant: 10.0),
            timeSlider.heightAnchor.constraint(equalTo: bottomMaskView.heightAnchor, multiplier: 30/32),
            timeSlider.trailingAnchor.constraint(equalTo: timeProgressLabel.leadingAnchor, constant: -10.0)
        ])
        
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.centerYAnchor.constraint(equalTo: timeSlider.centerYAnchor),
            progressView.leadingAnchor.constraint(equalTo: timeSlider.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: timeSlider.trailingAnchor),
            progressView.heightAnchor.constraint(equalTo: timeSlider.heightAnchor, multiplier: 2.0/30.0)
        ])

        timeProgressLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeProgressLabel.centerYAnchor.constraint(equalTo: bottomMaskView.centerYAnchor),
            timeProgressLabel.heightAnchor.constraint(equalTo: bottomMaskView.heightAnchor),
            timeProgressLabel.trailingAnchor.constraint(equalTo: fullScreenBtn.leadingAnchor, constant: -10)
        ])
    
        fullScreenBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fullScreenBtn.trailingAnchor.constraint(equalTo: bottomMaskView.trailingAnchor, constant: -10),
            fullScreenBtn.topAnchor.constraint(equalTo: bottomMaskView.topAnchor, constant: 8),
            fullScreenBtn.bottomAnchor.constraint(equalTo: bottomMaskView.bottomAnchor, constant: -8),
            fullScreenBtn.widthAnchor.constraint(equalTo: fullScreenBtn.heightAnchor)
        ])
        
        
        seekToView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seekToView.centerYAnchor.constraint(equalTo: mainMaskView.centerYAnchor),
            seekToView.centerXAnchor.constraint(equalTo: mainMaskView.centerXAnchor),
            seekToView.widthAnchor.constraint(equalToConstant: 100),
            seekToView.heightAnchor.constraint(equalToConstant: 40)
        ])

        seekToViewImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seekToViewImage.leadingAnchor.constraint(equalTo: seekToView.leadingAnchor, constant: 15),
            seekToViewImage.centerYAnchor.constraint(equalTo: seekToView.centerYAnchor),
            seekToViewImage.heightAnchor.constraint(equalTo: seekToView.heightAnchor, multiplier: 15/40),
            seekToViewImage.widthAnchor.constraint(equalTo: seekToViewImage.heightAnchor, multiplier: 25/15)
        ])

        seekToLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            seekToLabel.leadingAnchor.constraint(equalTo: seekToViewImage.trailingAnchor, constant: 10),
            seekToLabel.centerYAnchor.constraint(equalTo: seekToView.centerYAnchor),
            seekToLabel.trailingAnchor.constraint(equalTo: seekToView.trailingAnchor, constant: -10)
        ])
    }
    
    // MARK: - Initialization & Dealloc
    
    // Initial
    public convenience init() {
        // MARK: - need to give a size to avoid constraints crash
        self.init(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 100)))
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubViews()
        setViewSettings()
        setViewActions()
        setViewConstraints()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubViews()
        setViewSettings()
        setViewActions()
        setViewConstraints()
    }
    
    deinit {
        
    }
}
