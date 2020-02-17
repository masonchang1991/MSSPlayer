//
//  PlayerReplayView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/22.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol PlayerReplayViewDelegate: class {
    func playerReplayView(_ replayView: PlayerReplayView, didReplay replay: Bool)
    func playerReplayView(_ replayView: PlayerReplayView, didCancel cancel: Bool)
}

public protocol PlayerReplayView: UIView {
    // MARK: - Parameters
    var delegate: PlayerReplayViewDelegate? { get set }
    // MARK: - UI Display methods
    func show()
    func hide()
}

open class MSSPlayerReplayView: UIView, PlayerReplayView {
    
    // MARK: - UI Components
    public let imageView = UIImageView()
    
    open var trackLayer: CAShapeLayer
    open var progressLayer: CAShapeLayer
    open var basicAnimation: CABasicAnimation
    
    // MARK: - Parameters
    open var lineWidthAspectRatio: CGFloat = 0.1
    open var imageSize: CGSize = .zero
    open var circularPath: UIBezierPath {
        let radius = imageSize.width / 2
        return UIBezierPath(arcCenter: CGPoint(x: bounds.width / 2, y: bounds.height / 2),
                            radius: ceil(radius - radius * lineWidthAspectRatio),
                            startAngle: -.pi / 2,
                            endAngle: 2 * .pi,
                            clockwise: true)
    }
    
    // Delegates or Closures
    open weak var delegate: PlayerReplayViewDelegate?
    
    // MARK: - Open methods
    
    open func show() {
        isHidden = false
        startPreparing()
    }
    
    open func hide() {
        isHidden = true
        pausePreparing()
    }
    
    open func startPreparing() {
        progressLayer.add(basicAnimation, forKey: "roundCircle")
    }
    
    open func pausePreparing() {
        progressLayer.removeAnimation(forKey: "roundCircle")
    }
    
    // MARK: - Private methods
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.addGestureRecognizer(tap)
    }
    
    @objc private func handleTap() {
        delegate?.playerReplayView(self, didReplay: true)
    }
    
    // MARK: - View Settings
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        let radius = imageSize.width / 2
        imageView.layer.cornerRadius = radius
        imageView.center = center
        
        trackLayer.path = circularPath.cgPath
        trackLayer.lineWidth = ceil(radius * lineWidthAspectRatio)
        progressLayer.path = circularPath.cgPath
        progressLayer.lineWidth = ceil(radius * lineWidthAspectRatio)
    }
    
    private func setupViews() {
        addSubview(imageView)
        imageView.frame = CGRect(origin: .zero,
                                 size: imageSize)
        imageView.center = center
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        layer.addSublayer(trackLayer)
        layer.addSublayer(progressLayer)
        self.basicAnimation.delegate = self
    }
    
    // MARK: - initialization and deallocation
    
    convenience public init() {
        self.init(size: CGSize(width: 40, height: 40), image: MSSImageResource.get(.mss_replay))
    }
    
    convenience public init(size: CGSize, image: UIImage?) {
        ///Set default layer and animation
        let trackLayer = CAShapeLayer()
        trackLayer.strokeColor = UIColor.gray.withAlphaComponent(0.54).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineCap = CAShapeLayerLineCap.round
        
        let progressLayer = CAShapeLayer()
        progressLayer.strokeColor = UIColor.white.withAlphaComponent(0.87).cgColor
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = CAShapeLayerLineCap.round
        progressLayer.strokeEnd = 0
        
        let basicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        basicAnimation.toValue = 1
        basicAnimation.duration = 5
        basicAnimation.fillMode = .forwards
        basicAnimation.isRemovedOnCompletion = false
        
        self.init(image: image,
                  imageSize: size,
                  trackLayer: trackLayer,
                  progressLayer: progressLayer,
                  basicAnimation: basicAnimation)
    }
    
    @objc public init(image: UIImage?, imageSize: CGSize, trackLayer: CAShapeLayer, progressLayer: CAShapeLayer, basicAnimation: CABasicAnimation) {
        self.trackLayer = trackLayer
        self.progressLayer = progressLayer
        self.basicAnimation = basicAnimation
        self.imageSize = imageSize
        self.imageView.image = image
        super.init(frame: UIScreen.main.bounds)
        setupViews()
        setupGestures()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MSSPlayerReplayView: CAAnimationDelegate {
    public func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        // flag is true mean completed
        if flag { delegate?.playerReplayView(self, didReplay: true) }
    }
}

