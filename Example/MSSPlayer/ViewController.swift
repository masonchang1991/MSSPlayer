//
//  ViewController.swift
//  MSSPlayer
//
//  Created by masonchang1991 on 02/17/2020.
//  Copyright (c) 2020 masonchang1991. All rights reserved.
//

import UIKit
import MSSPlayer

class ViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    let playerController = MSSPlayerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playerController.setPlayerOn(view: containerView, with: .landScapeRightFullScreen)
        
        let resourse1 = MSSPlayerResource(URL(string: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8")!)
        let resourse2 = MSSPlayerResource(URL(string: "http://184.72.239.149/vod/smil:BigBuckBunny.smil/playlist.m3u8")!)
        playerController.setResources([resourse1, resourse2])
        playerController.containerView.setBgCoverWith(image: UIImage(named: "bg_image"), type: .none)
        playerController.play(with: 1.0, startAtPercentDuration: 0.5)
    }
}

