//
//  Extensions.swift
//  MPlayer
//
//  Created by Mason on 2020/1/9.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension UIApplication {
    static var sceneKeyWindow: UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }
}
