//
//  MPTimeSlider.swift
//  MPlayer
//
//  Created by Mason on 2020/1/13.
//  Copyright © 2020 Mason. All rights reserved.
//

import UIKit

public class MSSTimeSlider: UISlider {
    override open func trackRect(forBounds bounds: CGRect) -> CGRect {
        let trackHeigt:CGFloat = bounds.height * 2 / 25
        let position = CGPoint(x: 0 , y: (bounds.height - 1) / 2 - trackHeigt / 2)
        let customBounds = CGRect(origin: position, size: CGSize(width: bounds.size.width, height: trackHeigt))
        super.trackRect(forBounds: customBounds)
        return customBounds
    }
    
    override open func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let rect = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        let newx = rect.origin.x - (bounds.width * 0.02)
        let width = bounds.height / 2
        let height = bounds.height / 2
        let newRect = CGRect(x: newx, y: bounds.height / 4, width: width, height: height)
        return newRect
    }
    
    override open func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        return true
    }
}
