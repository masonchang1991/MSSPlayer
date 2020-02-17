//
//  PlayerGestureView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public struct PlayerGestureOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    // rawValue need to do shifting, refer: https://developer.apple.com/documentation/swift/optionset
    static public let panVertical = PlayerGestureOptions(rawValue: 1 << 0)
    static public let panHorizontal = PlayerGestureOptions(rawValue: 1 << 1)
    static public let singleTap = PlayerGestureOptions(rawValue: 2 << 2)
    static public let doubleTap = PlayerGestureOptions(rawValue: 3 << 3)
    static public let all: PlayerGestureOptions = [.panVertical, .panHorizontal, .singleTap, .doubleTap]
}

public enum PanDirection {
    case horizontal
    case vertical
}

public protocol PlayerGestureViewDelegate: class {
    func gestureView(_ gestureView: PlayerGestureView, doubleTapWith numberOfTouch: Int)
    func gestureView(_ gestureView: PlayerGestureView, singleTapWith numberOfTouch: Int)
    func gestureView(_ gestureView: PlayerGestureView, state: UIGestureRecognizer.State, velocityPoint: CGPoint)
}

public extension PlayerGestureViewDelegate {
    func gestureView(_ gestureView: PlayerGestureView, doubleTapWith numberOfTouch: Int) { }
    func gestureView(_ gestureView: PlayerGestureView, singleTapWith numberOfTouch: Int) { }
    func gestureView(_ gestureView: PlayerGestureView, state: UIGestureRecognizer.State, velocityPoint: CGPoint) { }
}

public protocol PlayerGestureView: UIView {
    var panStartLocation: CGPoint { get set }
    var panDirection: PanDirection { get set }
    var delegate: PlayerGestureViewDelegate? { get set }
    
    func disableGestures(_ gestures: PlayerGestureOptions)
    func enableGestures(_ gestures: PlayerGestureOptions)
}

open class MSSPlayerGestureView: UIView, PlayerGestureView {
    
    // MARK: - Parameters
    open var panStartLocation: CGPoint = .zero
    open var panDirection: PanDirection = .horizontal
    private var panGesture: UIPanGestureRecognizer?
    private var singleTapGesture: UITapGestureRecognizer?
    private var doubleTapGesture: UITapGestureRecognizer?
    
    private var verticalPanIsDisable: Bool = false
    private var horizontalPanIsDisable: Bool = false
    
    open weak var delegate: PlayerGestureViewDelegate?
    
    open func disableGestures(_ gestures: PlayerGestureOptions) {
        if gestures.contains(.panVertical) {
            verticalPanIsDisable = true
        }
        if gestures.contains(.panHorizontal) {
            horizontalPanIsDisable = true
        }
        if gestures.contains(.singleTap) {
            singleTapGesture?.isEnabled = false
        }
        if gestures.contains(.doubleTap){
            doubleTapGesture?.isEnabled = false
        }
    }
    
    open func enableGestures(_ gestures: PlayerGestureOptions) {
        if gestures.contains(.panVertical) {
            verticalPanIsDisable = false
        }
        if gestures.contains(.panHorizontal) {
            horizontalPanIsDisable = false
        }
        if gestures.contains(.singleTap) {
            singleTapGesture?.isEnabled = true
        }
        if gestures.contains(.doubleTap){
            doubleTapGesture?.isEnabled = true
        }
    }
    
    private func addGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        addGestureRecognizer(panGesture)
        self.panGesture = panGesture
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGesture)
        self.singleTapGesture = singleTapGesture
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        self.doubleTapGesture = doubleTapGesture
        
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        switch gesture.numberOfTapsRequired {
        case 1: delegate?.gestureView(self, singleTapWith: gesture.numberOfTouches)
        case 2: delegate?.gestureView(self, doubleTapWith: gesture.numberOfTouches)
        default: break
        }
    }
    
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        let locationPoint = gesture.location(in: self)
        let velocityPoint = gesture.velocity(in: self)
        switch gesture.state {
        case .began:
            // 使用絕對值來判斷移動方向
            let horizontalValue = abs(velocityPoint.x)
            let verticalValue = abs(velocityPoint.y)
            panDirection = horizontalValue > verticalValue ? .horizontal: .vertical
            switch panDirection {
            case .vertical:
                if verticalPanIsDisable { return }
            case .horizontal:
                if horizontalPanIsDisable { return }
            }
            
            panStartLocation = locationPoint
            delegate?.gestureView(self, state: gesture.state, velocityPoint: velocityPoint)
        default:
            switch panDirection {
            case .vertical:
                if verticalPanIsDisable { return }
            case .horizontal:
                if horizontalPanIsDisable { return }
            }
            delegate?.gestureView(self, state: gesture.state, velocityPoint: velocityPoint)
        }
    }
    
    // MARK: - initialization and deallocation
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addGestures()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
