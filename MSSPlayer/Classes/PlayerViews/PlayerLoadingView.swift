//
//  PlayerLoadingView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol PlayerLoadingView: UIView {
    // UI Display methods
    func show()
    func hide()
    func startLoading()
    func endLoading()
}

open class MSSPlayerLoadingView: UIView, PlayerLoadingView {
    
    // MARK: - UI Components
    
    fileprivate let mainMaskView: UIView = UIView()
    fileprivate lazy var loadingIndicatorView: UIActivityIndicatorView = {
        if #available(iOS 13.0, *) {
            let indicatorView = UIActivityIndicatorView(style: .large)
            indicatorView.color = .white
            return indicatorView
        } else {
            return UIActivityIndicatorView(style: .gray)
        }
    }()
    
    // MARK: - Open Methods - UI Display
    
    open func startLoading() {
        loadingIndicatorView.startAnimating()
    }
    
    open func endLoading() {
        loadingIndicatorView.stopAnimating()
    }
    
    open func show() {
        isHidden = false
        setNeedsDisplay()
    }
    
    open func hide() {
        isHidden = true
        setNeedsDisplay()
    }
    
    // MARK: - View Settings
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        loadingIndicatorView.frame = CGRect(origin: .zero,
                                        size: CGSize(width: 40,
                                                     height: 40))
        loadingIndicatorView.center = mainMaskView.center
    }
    
    open func addSubviews() {
        addSubview(mainMaskView)
        mainMaskView.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
        addSubview(loadingIndicatorView)
    }
    
    open func setViewSettings() {
        isUserInteractionEnabled = false
    }
    
    open func setViewConstraints() {
        mainMaskView.frame = bounds
        mainMaskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        loadingIndicatorView.frame = CGRect(origin: .zero,
                                        size: CGSize(width: 40,
                                                     height: 40))
        loadingIndicatorView.center = mainMaskView.center
        startLoading()
    }
    
    // MARK: - initialization and deallocation
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        setViewSettings()
        setViewConstraints()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubviews()
        setViewSettings()
        setViewConstraints()
    }
}

