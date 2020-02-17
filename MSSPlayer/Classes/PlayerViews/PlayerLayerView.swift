//
//  PlayerLayerView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/7.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

public enum DisplaySizeType {
    case normal                           /// 16:9 ，以寬為基值，且將 videoGravity 設成 resizeAspectFill
    case fillContainer                    /// 填充滿 container
    case widthBaseRatio(CGFloat)          /// 以寬為基值，且將 videoGravity 設成 resizeAspectFill
    case heightBaseRatio(CGFloat)         /// 以高為基值，且將 videoGravity 設成 resizeAspectFill
}

public enum DisplayAlignmentType {
    case center
    case topRight                   /// 對齊上右
    case topLeft                    /// 對齊上左
    case bottomRight                /// 對齊下右
    case bottomLeft                 /// 對齊下左
}

public protocol PlayerLayerView: UIView {
    // Parameters
    var playerLayer: AVPlayerLayer { get set }
    var videoGravity: AVLayerVideoGravity { get set }
    var displaySize: DisplaySizeType { get set }
    var displayAlignment: DisplayAlignmentType { get set }
    
    // Open methods
    func setDisplayPlayer(_ player: AVPlayer)
    func setSizeAndAlignment(sizeType: DisplaySizeType, alignmentType: DisplayAlignmentType)
}
 
/// AVPlayerLayer as base layer's view
open class BasePlayerLayerView: UIView {
    open lazy var playerLayer: AVPlayerLayer = {
        let layer = self.layer as! AVPlayerLayer
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    open override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}

open class MSSPlayerLayerView: UIView, PlayerLayerView, Loggable {

    // MARK: - UI Components
    // Player Layer
    private let playerLayerView = BasePlayerLayerView(frame: .zero)
    open var playerLayer: AVPlayerLayer {
        get {
            playerLayerView.playerLayer
        }
        set { }
    }
    
    // MARK: - Parameters
    /// 影片的contentMode
    open var videoGravity: AVLayerVideoGravity = .resizeAspectFill {
        didSet {
            playerLayer.videoGravity = videoGravity
        }
    }

    /// DisplaySize 將幫助你定義影片呈現的尺寸，例如phone就是16:9
    open var displaySize: DisplaySizeType = .normal {
        didSet {
            playerLayer.setNeedsLayout()
            playerLayer.setNeedsDisplay()
            layoutIfNeeded()
        }
    }
    
    /// DisplayAlignment 協助你調整呈現的位置
    open var displayAlignment: DisplayAlignmentType = .center {
        didSet {
            playerLayer.setNeedsLayout()
            playerLayer.setNeedsDisplay()
            layoutIfNeeded()
        }
    }
    
    // MARK: - Open methods
    
    open func setDisplayPlayer(_ player: AVPlayer) {
        playerLayer.player = player
    }
    
    open func setSizeAndAlignment(sizeType: DisplaySizeType, alignmentType: DisplayAlignmentType) {
        self.displaySize = sizeType
        self.displayAlignment = alignmentType
        layoutSubviews()
    }
    
    // MARK: - Private methods
    
    private func setupPlayerLayer() {
        addSubview(playerLayerView)
        clipsToBounds = true
    }
    
    private func calculateDisplaySize() -> CGSize {
        let playerLayerViewSize: CGSize = bounds.size
        switch displaySize {
        case .normal:
            let ratio: CGFloat = 9 / 16
            return CGSize(width: playerLayerViewSize.height / ratio,
                          height: playerLayerViewSize.height)
        case .heightBaseRatio(let ratio):
            return CGSize(width: playerLayerViewSize.height * ratio,
                          height: playerLayerViewSize.height)
        case .widthBaseRatio(let ratio):
            return CGSize(width: playerLayerViewSize.width,
                          height: playerLayerViewSize.width * ratio)
        case .fillContainer:
            return CGSize(width: bounds.width,
                          height: bounds.height)
        }
    }
    
    // MARK: - View Settings
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        let playerLayerSize = calculateDisplaySize()
        switch displayAlignment {
        case .center:
            playerLayerView.frame.size = playerLayerSize
            // 中心對準 playerLayerView 的中心
            playerLayerView.center = center
        case .topLeft:
            playerLayerView.frame = CGRect(origin: .zero,
                                           size: playerLayerSize)
        case .topRight:
            playerLayerView.frame = CGRect(x: bounds.width - playerLayerSize.width,
                                           y: .zero,
                                           width: playerLayerSize.width,
                                           height: playerLayerSize.height)
        case .bottomLeft:
            playerLayerView.frame = CGRect(x: .zero,
                                           y: bounds.height - playerLayerSize.height,
                                           width: playerLayerSize.width,
                                           height: playerLayerSize.height)
        case .bottomRight:
            playerLayerView.frame = CGRect(x: bounds.width - playerLayerSize.width,
                                           y: bounds.height - playerLayerSize.height,
                                           width: playerLayerSize.width,
                                           height: playerLayerSize.height)
        }
    }
    
    // MARK: - initalization and deallocation
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayerLayer()
    }
}
