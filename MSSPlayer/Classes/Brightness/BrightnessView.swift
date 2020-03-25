//
//  BrightnessView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/16.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol BrightnessView: UIView {
    // UI Display methods
    func show(animated: Bool)
    func disappear(animated: Bool)
    // Open methods
    func getCurrentBrightnessLevel() -> CGFloat
    func updateBrightnessLevelWith(_ brightnessLevel: CGFloat)
}

open class MSSPlayerBrightnessView: UIView, BrightnessView {
    
    // UI Components
    private var bgImageView = UIImageView()
    private var titleLabel = UILabel()
    private var brightnessLevelView = UIView()
    private var tipArray = NSMutableArray()
    
    // Parameters
    private(set) var isShowing: Bool = false
    private var presentItem: DispatchWorkItem?
    
    private var screenWidth: CGFloat {
        return UIScreen.main.bounds.size.width
    }
    private var screenHeight: CGFloat {
        return UIScreen.main.bounds.size.height
    }
    
    lazy var keyWindow: UIWindow? = {
        if #available (iOS 13.0, *) {
            return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }()
    
    // MARK: - UI Display methods
    
    open func show(animated: Bool) {
        cancelCurrentPresentAction()
        presentItem = DispatchWorkItem(block: { [weak self] in
            guard let self = self else { return }
            if animated {
                UIView.animate(withDuration: 0.2, animations: {
                    if !self.isShowing {
                        self.keyWindow?.addSubview(self)
                    }
                    self.alpha = 1.0
                }) { (isFinish) in
                    if isFinish {
                        self.isShowing = true
                    }
                }
            } else {
                if !self.isShowing {
                    self.keyWindow?.addSubview(self)
                }
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
                UIView.animate(withDuration: 0.2, animations: {
                    self.alpha = 0.0
                }) { (isFinish) in
                    if isFinish {
                        self.removeFromSuperview()
                        self.isShowing = false
                    }
                }
            } else {
                self.alpha = 0.0
                self.removeFromSuperview()
                self.isShowing = false
            }
        })
        if let item = presentItem {
            DispatchQueue.main.async(execute: item)
        }
    }
    
    // MARK: - Open methods
    open func getCurrentBrightnessLevel() -> CGFloat {
        return UIScreen.main.brightness
    }
    
    open func updateBrightnessLevelWith(_ brightnessLevel: CGFloat) {
        if isShowing {
            // change UI
            let stage: CGFloat = 1 / 15.0
            let level: Int =  Int(brightnessLevel / stage)
            for index in 0..<tipArray.count {
                guard let tipImageView = tipArray[index] as? UIImageView else { return }
                if index <= level {
                    tipImageView.isHidden = false
                } else {
                    tipImageView.isHidden = true
                }
            }
        }
        UIScreen.main.brightness = brightnessLevel
    }
    
    // MARK: - Private methods
    
    private func cancelCurrentPresentAction() {
        guard let presentItem = presentItem else { return }
        presentItem.cancel()
    }
    
    // MARK: - View setting methods
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // check keywindow exist
        guard let keyWindow = keyWindow else { return }
        self.center = keyWindow.center
        
        // update tips frame
        let tipW = (brightnessLevelView.bounds.size.width - 17) / 16
        let tipH: CGFloat = 5
        let tipY: CGFloat = 1
        
        for (index, tipImageView) in tipArray.enumerated() {
            let tipX = CGFloat(index) * (tipW + 1) + 1
            (tipImageView as? UIView)?.frame = CGRect(x: tipX, y: tipY, width: tipW, height: tipH)
        }
    }
    
    private func setupUI() {
        layer.cornerRadius = 10
        layer.masksToBounds = true
        
        // 毛玻璃效果
        let toolbar = UIToolbar(frame: bounds)
        toolbar.barTintColor = UIColor(red: 199.0/255.0,
                                       green: 199.0/255.0,
                                       blue: 203.0/255.0,
                                       alpha: 1.0)
        addSubview(toolbar)
        addSubview(bgImageView)
        addSubview(titleLabel)
        addSubview(brightnessLevelView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.heightAnchor.constraint(equalToConstant: 30.0)
        ])
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = UIColor(red: 0.25,
                                       green: 0.22,
                                       blue: 0.21,
                                       alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.text = "Brightness"
        
        bgImageView.image = MSSImageResource.get(.mss_brightness)
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bgImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            bgImageView.widthAnchor.constraint(equalTo: bgImageView.heightAnchor),
            bgImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: brightnessLevelView.topAnchor, constant: -5)
        ])
        
        brightnessLevelView.backgroundColor = UIColor(red: 0.22, green: 0.22, blue: 0.21, alpha: 1.0)
        brightnessLevelView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            brightnessLevelView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 13),
            brightnessLevelView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -13),
            brightnessLevelView.heightAnchor.constraint(equalToConstant: 7.5),
            brightnessLevelView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
        createTips()
        alpha = 0.0
    }
    
    // 建立 Tips
    private func createTips() {
        self.tipArray = NSMutableArray(capacity: 16)
        let tipW = (brightnessLevelView.bounds.size.width - 17) / 16
        let tipH: CGFloat = 5
        let tipY: CGFloat = 1
        
        for index in 0..<16 {
            let tipX = CGFloat(index) * (tipW + 1) + 1
            let tipImageView = UIImageView()
            tipImageView.backgroundColor = UIColor.white
            tipImageView.frame = CGRect(x: tipX, y: tipY, width: tipW, height: tipH)
            brightnessLevelView.addSubview(tipImageView)
            tipArray.add(tipImageView)
        }
        setInitialBrightnessLevelWith(UIScreen.main.brightness)
    }
    
    private func setInitialBrightnessLevelWith(_ brightnessLevel: CGFloat) {
        let stage: CGFloat = 1 / 15.0
        let level: Int =  Int(brightnessLevel / stage)
        for index in 0..<tipArray.count {
            guard let tipImageView = tipArray[index] as? UIImageView else { return }
            if index <= level {
                tipImageView.isHidden = false
            } else {
                tipImageView.isHidden = true
            }
        }
    }
    
    // MARK: - initalization and deallocation
    
    public convenience init() {
        let defaultFrame = CGRect(x: 0,
                                  y: 0,
                                  width: 155,
                                  height: 155)
        self.init(frame: defaultFrame)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
}
