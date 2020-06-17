//
//  PlayerBackgroundView.swift
//  MPlayer
//
//  Created by Mason on 2020/2/12.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit
import Accelerate

public enum PlayerBackgroundType {
    case none
    case blur  /// tent blur, reference from https://developer.apple.com/documentation/accelerate/vimage/blurring_an_image
    case custom(key: String)
}

public protocol PlayerBackgroundView: UIView {
    var bgCoverType: PlayerBackgroundType { get set }
    
    func setBgCoverWith(image: UIImage?, type: PlayerBackgroundType)
    func setBgCoverWith(urlRequest: URLRequest?, type: PlayerBackgroundType)
}

open class MSSPlayerBackgroundView: UIView, PlayerBackgroundView, Loggable {
    
    // MARK: - UI Components
    lazy open var backgroundImageView: UIImageView = UIImageView()
    
    // MARK: - Parameters
    public var bgCoverType: PlayerBackgroundType = .none
    
    private let kernelLength = 51
    lazy private var destinationBuffer = vImage_Buffer()
    lazy private var format: vImage_CGImageFormat = vImage_CGImageFormat()
    lazy private var sourceBuffer: vImage_Buffer = vImage_Buffer()
    
    // MARK: - Open methods
    open func setBgCoverWith(image: UIImage?, type: PlayerBackgroundType) {
        switch type {
        case .blur:
            setCoverImage(image)
            applyBlur()
        case .none, .custom:
            setCoverImage(image)
        }
        bgCoverType = type
    }
    
    open func setBgCoverWith(urlRequest: URLRequest?, type: PlayerBackgroundType) {
        switch type {
        case .blur:
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                guard let urlRequest = urlRequest else { return }
                let urlSession = URLSession(configuration: URLSessionConfiguration.default)
                urlSession.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if let dataUnwrapped = data {
                            self.setBgCoverWith(image: UIImage(data: dataUnwrapped), type: .blur)
                        } else {
                            self.setBgCoverWith(image: nil, type: .blur)
                        }
                    }
                }).resume()
            }
        case .none, .custom:
            DispatchQueue.global().async { [weak self] in
                guard let self = self else { return }
                guard let urlRequest = urlRequest else { return }
                let urlSession = URLSession(configuration: URLSessionConfiguration.default)
                urlSession.dataTask(with: urlRequest, completionHandler: { (data, response, error) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        if let dataUnwrapped = data {
                            self.setBgCoverWith(image: UIImage(data: dataUnwrapped), type: type)
                        } else {
                            self.setBgCoverWith(image: nil, type: type)
                        }
                    }
                }).resume()
            }
        }
    }
    
    // MARK: - Private methods
    private func setCoverImage(_ image: UIImage?) {
        guard let image = image else { backgroundImageView.image = nil; return }
        if #available(iOS 13.0, *) {
            // Reset vImage_CGImageFormat
            if
                let cgImage = image.cgImage,
                let newFormat = vImage_CGImageFormat(cgImage: cgImage) {
                format = newFormat
            }
            // Reset vImage_Buffer
            if let cgImage = image.cgImage,
                var sourceImageBuffer = try? vImage_Buffer(cgImage: cgImage),
                var newScaledBuffer = try? vImage_Buffer(width: Int(sourceImageBuffer.width / 4),
                                                         height: Int(sourceImageBuffer.height / 4),
                                                         bitsPerPixel: format.bitsPerPixel) {
                vImageScale_ARGB8888(&sourceImageBuffer,
                                     &newScaledBuffer,
                                     nil,
                                     vImage_Flags(kvImageNoFlags))
                sourceBuffer = newScaledBuffer
            }
        }
        backgroundImageView.image = image
    }
    
    private func applyBlur() {
        if #available(iOS 13.0, *) {
            do {
                destinationBuffer = try vImage_Buffer(width: Int(sourceBuffer.width),
                                                      height: Int(sourceBuffer.height),
                                                      bitsPerPixel: format.bitsPerPixel)
            } catch {
                return
            }
            
            tentBlur()
            
            if let result = try? destinationBuffer.createCGImage(format: format) {
                backgroundImageView.image = UIImage(cgImage: result)
            }
            
            destinationBuffer.free()
        }
    }
    
    private func tentBlur() {
        vImageTentConvolve_ARGB8888(&sourceBuffer,
                                    &destinationBuffer,
                                    nil,
                                    0, 0,
                                    UInt32(kernelLength),
                                    UInt32(kernelLength),
                                    nil,
                                    vImage_Flags(kvImageEdgeExtend))
    }
    
    // MARK: - Views Setting
    private func addSubViews() {
        addSubview(backgroundImageView)
    }
    
    private func setViewConstraints() {
        backgroundImageView.frame = bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    private func setViewSettings() {
        backgroundImageView.backgroundColor = .black
    }
    
    // MARK: - Initialization & Deallocation
    convenience public init() {
        self.init(frame: .zero)
    }
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubViews()
        setViewConstraints()
        setViewSettings()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubViews()
        setViewConstraints()
        setViewSettings()
    }
    
    deinit {
        log(type: .debug, msg: classForCoder, "dealloc")
    }
}

