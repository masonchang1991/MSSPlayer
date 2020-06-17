//
//  PlayerStartView.swift
//  MPlayer
//
//  Created by Mason on 2020/1/17.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit

public protocol PlayerStartView: UIView {
    // MARK: - UI Display Methods
    func show()
    func hide()
    
    // MARK: - Open methods
    func setCoverBy(url: URL, placeholderImage: UIImage?)
    func setCoverBy(image: UIImage, placeholderImage: UIImage?)
}

open class MSSPlayerStartView: UIView, PlayerStartView {
    
    // MARK: -  UI Components
    fileprivate let blurEffect = UIBlurEffect(style: .light)
    fileprivate lazy var blurView: UIVisualEffectView = {
        return UIVisualEffectView(effect: blurEffect)
    }()
    fileprivate let blurImageView = UIImageView(image: nil)
    fileprivate let coverImageView = UIImageView(image: nil)
    
    // MARK: - Open methods
    
    open func setCoverBy(url: URL, placeholderImage: UIImage?) {
        blurImageView.image = placeholderImage
        coverImageView.image = placeholderImage
        
        blurImageView.setupImage(from: url)
        coverImageView.setupImage(from: url)
    }
    
    open func setCoverBy(image: UIImage, placeholderImage: UIImage?) {
        blurImageView.image = placeholderImage
        coverImageView.image = placeholderImage
        
        blurImageView.image = image
        coverImageView.image = image
    }
    
    open func show() {
        isHidden = false
    }
    
    open func hide() {
        isHidden = true
    }
    
    // MARK: - View Settings
    
    open func addSubviews() {
        addSubview(blurImageView)
        addSubview(blurView)
        blurView.contentView.addSubview(coverImageView)
    }
    
    open func setViewSettings() {
        backgroundColor = .clear
        
        blurImageView.backgroundColor = .clear
        blurImageView.contentMode = .scaleAspectFill
        blurImageView.clipsToBounds = true
        
        coverImageView.backgroundColor = .clear
        coverImageView.contentMode = .scaleAspectFit
        coverImageView.clipsToBounds = true
    }
    
    open func setViewConstraints() {
        blurImageView.frame = bounds
        blurImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        coverImageView.frame = bounds
        coverImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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

extension UIImageView {
    func setupImage(from urlString: String?) -> Void {
        guard let urlString = urlString else { return }
        setupImage(from: URL(string: urlString))
    }
    
    func setupImage(from url: URL?) -> Void {
        guard let url = url else { return }
        
        let task = URLSession(configuration: .default).dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self, let data = data, error == nil else { return }
            DispatchQueue.main.async() { [weak self] in // execute on main thread
                guard let self = self else { return }
                self.image = UIImage(data: data)
            }
        }
        task.resume()
    }
}


