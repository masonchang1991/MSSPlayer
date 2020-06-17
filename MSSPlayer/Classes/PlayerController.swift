//
//  PlayerController.swift
//  MPlayer
//
//  Created by Mason on 2020/1/8.
//  Copyright © 2020 Mason. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc public protocol PlayerControllerListener: class {
    func playStateDidChangeTo(playing: Bool)
}

public enum PlayerControllerError: Error {
    case setResourceFail
}

public protocol PlayerControllerDelegate: NSObject {
    func playerController(_ controller: PlayerController, isPlaying: Bool)
    /// Call when tap fullscreen btn
    func playerController(_ controller: PlayerController, isFullScreen: Bool)
    /// Call when controlView show state changed
    func playerController(_ controller: PlayerController, controlView: PlayerControlView, willAppear animated: Bool)
    func playerController(_ controller: PlayerController, controlView: PlayerControlView, didAppear animated: Bool)
    func playerController(_ controller: PlayerController, controlView: PlayerControlView, willDisappear animated: Bool)
    func playerController(_ controller: PlayerController, controlView: PlayerControlView, didDisappear animated: Bool)
    
    func playerController(_ controller: PlayerController, shouldAllowOrientationChangeFullScreenState orientation: UIDeviceOrientation, isCurrentFullScreen: Bool) -> Bool
    func playerController(_ controller: PlayerController, didChanged presentmode: PresentMode)
    func playerController(_ controller: PlayerController, willChanged presentmode: PresentMode)
}

public enum PlayerViewType {
    case container(PlayerBackgroundView)
    case playerLayer(PlayerLayerView)
    case gesture(PlayerGestureView)
    case landScapeControl(PlayerControlView)
    case portraitControl(PlayerControlView)
    case loading(PlayerLoadingView)
    case pause(PlayerPauseView)
    case replay(PlayerReplayView)
    case playNext(PlayerPlayNextView)
    case start(PlayerStartView)
}

public protocol PlayerController: NSObject, PlayerGestureViewDelegate {
    // MARK: - Presenter
    var presenter: PlayerPresenter { get set }
    
    // MARK: - UI Components
    var containerView: PlayerBackgroundView { get set }
    /// contain playerLayer
    var playerLayerView: PlayerLayerView { get set }
    /// all gestures at this view
    var gestureView: PlayerGestureView { get set }
    /// controlView for landScape
    var landScapeControlView: PlayerControlView { get set }
    /// controlView for portrait
    var portraitControlView: PlayerControlView { get set }
    /// for loading
    var loadingView: PlayerLoadingView { get set }
    /// pause will show
    var pauseView: PlayerPauseView { get set }
    /// play to the end and there doesn't exist next video
    var replayView: PlayerReplayView { get set }
    /// play to the end and there exist next video
    var playNextView: PlayerPlayNextView { get set }
    /// defaultView for preparing
    var startView: PlayerStartView { get set }

    // MARK: - Parameters
    var currentResourceIndex: Int { get set }
    var currentResource: PlayerResource? { get set }
    var resources: [PlayerResource] { get set }
    var player: AVPlayer { get set }
    var isPlaying: Bool { get set }
    var delegate: PlayerControllerDelegate? { get set }
    
    // MARK: - Open method - Asset Settings
    func setVideoBy(_ url: URL)
    func setVideoBy(_ asset: AVURLAsset)
    func setVideoBy(_ item: AVPlayerItem)
    func setResources(_ resources: [PlayerResource])
    func addResources(_ resources: [PlayerResource])
    func insertResource(_ resource: PlayerResource, at index: Int) throws
    func configPlayerBy(_ item: AVPlayerItem)
    func configPlayerBy(_ resource: PlayerResource, at index: Int)
    @discardableResult
    func changeResourceBy(key: String) -> Bool
    @discardableResult
    func changeResourceBy(index: Int) -> Bool
    func clearResource()
    
    // MARK: - Open methods - Player method
    func play(with rate: Float?)
    func play(with rate: Float?, startAtPercentDuration percent: Double)
    func autoPlay(with rate: Float?)
    func pause()
    func seek(to seconds: TimeInterval, force: Bool, completion: ((Bool) -> Void)?)
    func changeRate(_ rate: Float)
    
    // MARK: - Open methods - Player View Setting
    func changeControlView(_ controlView: PlayerControlView, isPortrait: Bool)
    func changePlayerStateViewBy(_ playerStateView: PlayerViewType)
    func getCurrentControlView() -> PlayerControlView
    func setPlayerOn(view: UIView)
    func setPlayerOn(view: UIView, with mode: PresentMode)
    func changeToFullScreen(_ isFullScreen: Bool, animated: Bool)
    
    // MARK: - Listener
    func addListener(_ listener: PlayerControllerListener)
    func removeListener(_ listener: PlayerControllerListener)
    
    // MARK: - Static method
    static func supportOrientations() -> UIInterfaceOrientationMask
}

public extension PlayerController {
    static func supportOrientations() -> UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    func setVideoBy(_ url: URL) {
        let asset = AVURLAsset(url: url)
        setVideoBy(asset)
    }

    func setVideoBy(_ asset: AVURLAsset) {
        let playerItem = AVPlayerItem(asset: asset)
        setVideoBy(playerItem)
    }

    func setVideoBy(_ item: AVPlayerItem) {
        let resource = MSSPlayerResource(item)
        self.setResources([resource])
    }
}

typealias PlayerViewDelegates = (PlayerControlViewDelegate & PlayerPauseViewDelegate & PlayerPlayNextViewDelegate & PlayerReplayViewDelegate)

open class MSSPlayerController: NSObject, PlayerController, Loggable, PlayerViewDelegates, PlayerPresenterDelegate {
    
    // MARK: - UI Compoments
    
    open var containerView: PlayerBackgroundView = MSSPlayerBackgroundView()
    open var playerLayerView: PlayerLayerView = MSSPlayerLayerView()
    open var gestureView: PlayerGestureView = MSSPlayerGestureView()
    open var landScapeControlView: PlayerControlView = MSSPlayerPortraitControlView()
    open var portraitControlView: PlayerControlView = MSSPlayerPortraitControlView()
    open var loadingView: PlayerLoadingView = MSSPlayerLoadingView()
    open var pauseView: PlayerPauseView = MSSPlayerPauseView()
    open var playNextView: PlayerPlayNextView = MSSPlayerPlayNextView()
    open var replayView: PlayerReplayView = MSSPlayerReplayView()
    open var startView: PlayerStartView = MSSPlayerStartView()
    
    // MARK: - Presenter - handle fullScreen transition
    
    open lazy var presenter: PlayerPresenter = {
        let presenter = MSSPlayerPresenter()
        presenter.delegate = self
        return presenter
    }()
    
    // MARK: - Parameters
    
    open var durationIsValid: Bool = false
    open var isPlayingBeforeSeeking: Bool = false
    open var isAutoPlay: Bool = false
    open var currentResourceIndex: Int = 0
    open var currentResource: PlayerResource?
    open var resources: [PlayerResource] = []
    open var player: AVPlayer
    open weak var delegate: PlayerControllerDelegate?
    open var isPlaying: Bool = false {
        didSet {
            if oldValue != isPlaying {
                delegate?.playerController(self, isPlaying: isPlaying)
            }
        }
    }
    
    // Private Parameters
    /// when asset loaded, video duration become valid will do this block
    private var waitForDurationValidBlock: (() -> ())?
    /// a computed property for player state
    private var currentPlayState: Bool {
        return player.rate != 0 && player.error == nil
    }
    private let listenerMap: NSHashTable<PlayerControllerListener> = NSHashTable<PlayerControllerListener>.weakObjects()
    
    // Gesture Parameters
    fileprivate var gestureChangeValue: CGFloat = 0.0
    
    /// State Parameters
    open var state: PlayerState = .empty
    
    /// Player Parameters
    fileprivate var shouldSeekTo: TimeInterval = 0
    fileprivate weak var timer: Timer?
    fileprivate var isSliderSliding: Bool = false
    
    // MARK: - Open method - Asset Settings
    
    open func setResources(_ resources: [PlayerResource]) {
        self.resources = resources
        if let firstItem = resources.first {
            configPlayerBy(firstItem, at: 0)
        }
    }
    
    open func addResources(_ resources: [PlayerResource]) {
        let originResourceCount = self.resources.count
        self.resources.append(contentsOf: resources)
        if
            originResourceCount == 0,
            let firstItem = resources.first {
            configPlayerBy(firstItem, at: 0)
        }
    }
    
    open func insertResource(_ resource: PlayerResource, at index: Int) throws {
        // check index exist
        if let _ = resources[exist: index] {
            resources.insert(resource, at: index)
        } else {
            throw PlayerControllerError.setResourceFail
        }
    }
    
    open func configPlayerBy(_ item: AVPlayerItem) {
        // MARK: - create a resource for this item
        let newResource = MSSPlayerResource(item)
        do {
            try insertResource(newResource, at: currentResourceIndex)
            configPlayerBy(newResource, at: currentResourceIndex)
        } catch {
            addResources([newResource])
            if resources.count != 0 {
                configPlayerBy(newResource, at: resources.count - 1)
            }
        }
    }
    
    open func configPlayerBy(_ resource: PlayerResource, at index: Int) {
        // Update state
        changeState(to: .initial)
        // Reset Player Layer
        playerLayerView.playerLayer.player = nil
        // Reset ControlView
        getCurrentControlView().resetControlView()
        // change player item and add observer
        let videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)])
        resource.playerItem.add(videoOutput)
        // reset duration's isValid state
        durationIsValid = false
        waitForDurationValidBlock = nil
        shouldSeekTo = 0
        player.replaceCurrentItem(with: resource.playerItem)
        // Reset Player Layer
        playerLayerView.playerLayer.player = player
        addObserversTo(resource.playerItem)
        // change resourece
        if let currentResourceItem = currentResource?.playerItem {
            removeObserversFrom(currentResourceItem)
        }
        currentResource = resource
        currentResourceIndex = index
        
        play()
    }
    
    @discardableResult
    open func changeResourceBy(key: String) -> Bool {
        // find resource by key
        guard let (index, resource) = resources.enumerated().filter({ $0.element.resourceKey == key }).first else { return false }
        configPlayerBy(resource, at: index)
        return true
    }
    
    @discardableResult
    open func changeResourceBy(index: Int) -> Bool {
        guard let resource = resources[exist: index] else { return false }
        configPlayerBy(resource, at: index)
        return true
    }
    
    open func clearResource() {
        // Update state
        changeState(to: .empty)
        // Reset Player Layer
        playerLayerView.playerLayer.player = nil
        // reset duration's isValid state
        durationIsValid = false
        waitForDurationValidBlock = nil
        shouldSeekTo = 0
        // remove current observers
        if let currentResourceItem = currentResource?.playerItem {
            removeObserversFrom(currentResourceItem)
        }
        player.replaceCurrentItem(with: nil)
        currentResource = nil
        currentResourceIndex = 0
    }
    
    // MARK: - Open method - Player methods
    
    open func play(with rate: Float? = nil) {
        if let rate = rate {
            player.playImmediately(atRate: rate)
            changeState(to: .playing)
            listenerMap.allObjects.forEach({ $0.playStateDidChangeTo(playing: true )})
        } else {
            player.play()
            changeState(to: .playing)
            listenerMap.allObjects.forEach({ $0.playStateDidChangeTo(playing: true )})
        }
    }
    
    open func play(with rate: Float?, startAtPercentDuration percent: Double) {
        play(with: rate)
        if durationIsValid {
            guard let duration = player.currentItem?.duration else { return }
            let targetTime = floor(duration.seconds * percent)
            state = .buffering
            seek(to: targetTime) { [weak self](isComplete) in
                guard let self = self else { return }
                if isComplete {
                    self.state = .readyToPlay
                } else {
                    self.log(type: .debug, msg: "seek fail")
                }
            }
        } else {
            // create block and when duration valid will execute this block
            waitForDurationValidBlock = { [weak self] in
                guard let self = self  else { return }
                guard let duration = self.player.currentItem?.duration else { return }
                let targetTime = floor(duration.seconds * percent)
                self.state = .buffering
                self.seek(to: targetTime, force: true) { (isComplete) in
                    if isComplete {
                        self.state = .readyToPlay
                    } else {
                        self.log(type: .debug, msg: "seek fail")
                    }
                }
            }
        }
    }
    
    open func autoPlay(with rate: Float? = nil) {
        if isAutoPlay { play(with: rate) }
    }
    
    open func pause() {
        player.pause()
        changeState(to: .pause)
        listenerMap.allObjects.forEach({ $0.playStateDidChangeTo(playing: false )})
    }
    
    open func seek(to seconds: TimeInterval, force: Bool = false, completion: ((Bool) -> Void)?) {
        if seconds.isNaN { completion?(false); return }
        if player.currentItem?.status == .readyToPlay || force {
            let targetTime = CMTimeMake(value: Int64(seconds), timescale: 1)
            player.seek(to: targetTime, toleranceBefore: .zero, toleranceAfter: .zero) { (isFinished) in
                completion?(isFinished)
            }
        } else {
            shouldSeekTo = seconds
            completion?(false)
        }
    }
    
    open func changeRate(_ rate: Float) {
        player.rate = rate
    }
    
    // MARK: - Open methods - Player View Setting
    
    open func changeControlView(_ controlView: PlayerControlView, isPortrait: Bool) {
        if isPortrait {
            changePlayerStateViewBy(.portraitControl(controlView))
        } else {
            changePlayerStateViewBy(.landScapeControl(controlView))
        }
    }
    
    open func changePlayerStateViewBy(_ playerStateView: PlayerViewType) {
        switch playerStateView {
        case .container(let view):
            let originFrame = containerView.frame
            let originResizingMask = containerView.autoresizingMask
            let originSuperView = containerView.superview
            originSuperView?.addSubview(view)
            view.frame = originFrame
            view.autoresizingMask = originResizingMask
            containerView.subviews.forEach({ (subView) in
                view.addSubview(subView)
            })
            
            containerView.removeFromSuperview()
            containerView = view
        case .playerLayer(let view):
            containerView.insertSubview(view, belowSubview: gestureView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            playerLayerView.removeFromSuperview()
            playerLayerView = view
            playerLayerView.playerLayer.player = player
        case .gesture(let view):
            containerView.insertSubview(view, aboveSubview: playerLayerView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            gestureView.subviews.forEach({ (subView) in
                view.addSubview(subView)
            })
            gestureView.removeFromSuperview()
            gestureView = view
            gestureView.delegate = self
        case .portraitControl(let view):
            let originFrame = portraitControlView.frame
            let originResizingMask = portraitControlView.autoresizingMask
            let originSuperView = portraitControlView.superview
            originSuperView?.addSubview(view)
            view.frame = originFrame
            view.autoresizingMask = originResizingMask
            removeListener(portraitControlView)
            addListener(view)
            portraitControlView.removeFromSuperview()
            portraitControlView = view
            portraitControlView.delegate = self
        case .landScapeControl(let view):
            let originFrame = landScapeControlView.frame
            let originResizingMask = landScapeControlView.autoresizingMask
            let originSuperView = landScapeControlView.superview
            originSuperView?.addSubview(view)
            view.frame = originFrame
            view.autoresizingMask = originResizingMask
            removeListener(landScapeControlView)
            addListener(view)
            landScapeControlView.removeFromSuperview()
            landScapeControlView = view
            landScapeControlView.delegate = self
        case .loading(let view):
            containerView.insertSubview(view, aboveSubview: gestureView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            loadingView.removeFromSuperview()
            loadingView = view
        case .pause(let view):
            containerView.insertSubview(view, aboveSubview: loadingView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            removeListener(pauseView)
            addListener(view)
            pauseView.removeFromSuperview()
            pauseView = view
            pauseView.delegate = self
        case .replay(let view):
            containerView.insertSubview(view, aboveSubview: pauseView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            replayView.removeFromSuperview()
            replayView = view
            replayView.delegate = self
        case .playNext(let view):
            containerView.insertSubview(view, aboveSubview: replayView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            playNextView.removeFromSuperview()
            playNextView = view
            playNextView.delegate = self
        case .start(let view):
            containerView.insertSubview(view, aboveSubview: playNextView)
            view.frame = containerView.bounds
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            startView.removeFromSuperview()
            startView = view
        }
    }
    
    open func getCurrentControlView() -> PlayerControlView {
        switch presenter.currentMode {
        case .portrait, .portraitFullScreen: return portraitControlView
        case .landScapeRightFullScreen, .landScapeLeftFullScreen: return landScapeControlView
        }
    }
    
    /// Set Player on view and default present mode is portrait
    open func setPlayerOn(view: UIView) {
        setPlayerOn(view: view, with: .portrait)
    }
    
    open func setPlayerOn(view: UIView, with mode: PresentMode) {
        switch mode {
        case .portrait:
            presenter.portraitContainerView = view
            presenter.setMode(.portrait, playerView: containerView, animated: false)
        case .landScapeRightFullScreen, .landScapeLeftFullScreen:
            presenter.portraitContainerView = view
            presenter.setMode(.portrait, playerView: containerView, animated: false)
            presenter.isPortraitFullScreen = false
            // 如果使用者在起始畫面就設定 player 的話，則有可能取不到 keyWindow，故添加延遲
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.changeToFullScreen(true, animated: false)
            }
        case .portraitFullScreen:
            presenter.portraitContainerView = view
            presenter.setMode(.portrait, playerView: containerView, animated: false)
            presenter.isPortraitFullScreen = true
            // 如果使用者在起始畫面就設定 player 的話，則有可能取不到 keyWindow，故添加延遲
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.changeToFullScreen(true, animated: false)
            }
        }
    }
    
    open func changeToFullScreen(_ isFullScreen: Bool, animated: Bool = true) {
        // 如果是 portraitFullScreen 的話，使用 portraitControlView
        if isFullScreen {
            if presenter.isPortraitFullScreen {
                landScapeControlView.removeFromSuperview()
                portraitControlView.removeFromSuperview()
                gestureView.addSubview(portraitControlView)
                portraitControlView.updateFullScrennState(isFullScreen: isFullScreen)
                portraitControlView.frame = gestureView.bounds
                portraitControlView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            } else {
                portraitControlView.removeFromSuperview()
                gestureView.addSubview(landScapeControlView)
                landScapeControlView.updateFullScrennState(isFullScreen: isFullScreen)
                landScapeControlView.frame = gestureView.bounds
                landScapeControlView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
        } else {
            portraitControlView.removeFromSuperview()
            landScapeControlView.removeFromSuperview()
            gestureView.addSubview(portraitControlView)
            portraitControlView.updateFullScrennState(isFullScreen: isFullScreen)
            portraitControlView.frame = gestureView.bounds
            portraitControlView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
        presenter.changeToFullScreen(isFullScreen, playerView: containerView, animated: animated)
    }
    
    // MARK: - Listener methods
    
    open func addListener(_ listener: PlayerControllerListener) {
        listenerMap.add(listener)
    }
    
    open func removeListener(_ listener: PlayerControllerListener) {
        listenerMap.remove(listener)
    }
    
    // MARK: - Update Method for inherit
    // Update status methods
    open func updateStatus(includeLoading: Bool = false) {
        if includeLoading {
            guard let playerItem = player.currentItem else { return }
            if playerItem.isPlaybackLikelyToKeepUp || playerItem.isPlaybackBufferFull {
                changeState(to: .bufferFinished)
            } else if playerItem.status == .failed {
                changeState(to: .error(playerItem.error))
            } else {
                changeState(to: .buffering)
            }
        }
        
        // value 0.0 pauses the video, while a value of 1.0 plays the current item at its natural rate.
        if player.rate == 0.0 {
            isPlaying = false
            if let error = player.error {
                changeState(to: .error(error)); return
            }
            guard let currentItem = player.currentItem else { changeState(to: .empty); return }
            if player.currentTime() >= currentItem.duration {
                videoPlayDidEnd()
            }
        } else {
            isPlaying = true
        }
    }
    
    // Timer handler
    open func updateStateAndVideoTime() {
        guard let playerItem = player.currentItem else { return }
        if playerItem.duration.timescale > 0 {
            let currentTime = CMTimeGetSeconds(player.currentTime())
            let totalTime = TimeInterval(playerItem.duration.value) / TimeInterval(playerItem.duration.timescale)
            // Notify time change
            getCurrentControlView().updateCurrentTime(currentTime, total: totalTime)
        }
    }
    
    // MARK: - KVO and notification
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keyPath = keyPath else { return }
        // Handle PlayerItem Status
        if
            let playerItem = object as? AVPlayerItem {
            switch keyPath {
            case "status":
                let newStatus: AVPlayerItem.Status
                if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                    newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                } else {
                    newStatus = .unknown
                }
                switch newStatus {
                case .readyToPlay:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state readyToPlay")
                    changeState(to: .readyToPlay)
                case .failed:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state fail")
                    changeState(to: .error(playerItem.error))
                case .unknown:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state unknown")
                @unknown default:
                    log(type: .debug, msg: "\(classForCoder.self) kvo state unknown case from new version")
                }
            case "loadedTimeRanges":
                // 計算緩衝進度
                if let timeInterval = availableDuration() {
                    let duration = playerItem.duration
                    let totalDuration = CMTimeGetSeconds(duration)
                    // TODO: - loadedTime changed
                    getCurrentControlView().updateLoadedTime(timeInterval, totalDuration: totalDuration)
                }
            case "playbackBufferEmpty":
                // 緩衝為空的時候
                if playerItem.isPlaybackBufferEmpty {
                    changeState(to: .buffering)
                }
            case "playbackLikelyToKeepUp":
                if playerItem.isPlaybackBufferEmpty && state == .readyToPlay {
                    changeState(to: .bufferFinished)
                }
            case "duration":
                if !playerItem.duration.isIndefinite && !durationIsValid {
                    waitForDurationValidBlock?()
                    durationIsValid = true
                }
            default: break
            }
        }
        if keyPath == "rate" {
            updateStatus()
        }
    }
    
    @objc private func videoPlayDidEnd() {
        changeState(to: .playedToTheEnd)
    }
    
    @objc func failedToPlayToEndTime(_ notification: Notification) {
        if let error = notification.userInfo!["AVPlayerItemFailedToPlayToEndTimeErrorKey"] as? Error {
            changeState(to: .error(error))
        }
    }
    
    // MARK: - Private methods
    // MARK: - State Machine
    private func changeState(to: PlayerState) {
        if state == to { return }
        self.log(type: .debug, msg: "change player state to \(to)")
        switch (state, to) {
        case (_, .initial):
            startView.show()
            pauseView.hide()
            loadingView.hide()
            playNextView.hide()
            replayView.hide()
//            getCurrentControlView().hideControlView(animated: false)
            getCurrentControlView().hideErrorView()
            state = to
        case (_, .playing):
            startView.hide()
            pauseView.hide()
            loadingView.hide()
            playNextView.hide()
            replayView.hide()
            getCurrentControlView().hideErrorView()
            activeTimer()
            state = to
        case (_, .pause):
            pauseView.show()
            loadingView.hide()
            getCurrentControlView().hideErrorView()
            stopTimer()
            state = to
        case (_, .buffering):
            pauseView.hide()
            getCurrentControlView().hideErrorView()
            if player.currentItem?.isPlaybackLikelyToKeepUp ?? true {
                loadingView.hide()
            } else {
                loadingView.show()
            }
            state = to
        case (_, .bufferFinished):
            loadingView.hide()
            getCurrentControlView().hideErrorView()
            state = to
        case (_, .readyToPlay):
            loadingView.hide()
            getCurrentControlView().hideErrorView()
            if isAutoPlay {
                startView.hide()
                if shouldSeekTo > 0 {
                    log(type: .debug, msg: "\(classForCoder.self) should seek to \(shouldSeekTo)")
                    state = .buffering
                    seek(to: shouldSeekTo) { [weak self](isCompleted) in
                        guard let self = self else { return }
                        if isCompleted {
                            self.shouldSeekTo = 0
                            self.state = .readyToPlay
                        } else {
                            self.log(type: .debug, msg: "seek fail")
                        }
                    }
                } else {
                    state = to
                }
            } else {
                state = to
            }
            
        case (_, .playedToTheEnd):
            loadingView.hide()
            getCurrentControlView().hideErrorView()
            // Show play next view or replay view
            if let _ = resources[exist: currentResourceIndex + 1] {
                // show play next view
                playNextView.show()
            } else {
                // show replay view
                replayView.show()
            }
            timer?.invalidate()
            state = to
        case (_, .error(let error)):
            getCurrentControlView().showErrorViewWith(error!.localizedDescription)
        default:
            getCurrentControlView().hideErrorView()
            state = to
        }
    }
    
    // MARK: - Timer
    
    fileprivate func activeTimer() {
        if !(timer?.isValid ?? false) {
            timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self](_) in
                guard let self = self else { return }
                self.updateStateAndVideoTime()
            })
        }
        timer?.fireDate = Date()
    }
    
    fileprivate func stopTimer() {
        timer?.invalidate()
    }
    
    private func availableDuration() -> TimeInterval? {
        if
            let loadedTimeRanges = player.currentItem?.loadedTimeRanges,
            let first = loadedTimeRanges.first {
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSeconds = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSeconds
            return result
        } else {
            return nil
        }
    }
    
    // MARK: - View Settings
    
    fileprivate func setAllFunctionalViewsToContainerViews() {
        containerView.addSubview(playerLayerView)
        containerView.addSubview(gestureView)
        gestureView.addSubview(portraitControlView)
        containerView.addSubview(loadingView)
        containerView.addSubview(pauseView)
        containerView.addSubview(replayView)
        containerView.addSubview(playNextView)
        containerView.addSubview(startView)
        
        playerLayerView.frame = containerView.bounds
        playerLayerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        gestureView.frame = containerView.bounds
        gestureView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        gestureView.delegate = self
        
        landScapeControlView.delegate = self
        addListener(landScapeControlView)
        
        portraitControlView.frame = containerView.bounds
        portraitControlView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        portraitControlView.delegate = self
        addListener(portraitControlView)
        
        loadingView.frame = containerView.bounds
        loadingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        pauseView.frame = containerView.bounds
        pauseView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pauseView.delegate = self
        addListener(pauseView)
        
        replayView.frame = containerView.bounds
        replayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        replayView.delegate = self
        
        playNextView.frame = containerView.bounds
        playNextView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        playNextView.delegate = self
        
        startView.frame = containerView.bounds
        startView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    // MARK: - Observers add and remove
    
    private func addObserversTo(_ item: AVPlayerItem) {
        // NotificationCenter Observers
        let notiCenter = NotificationCenter.default
        notiCenter.addObserver(self,
                               selector: #selector(videoPlayDidEnd),
                               name: .AVPlayerItemDidPlayToEndTime,
                               object: item)
        notiCenter.addObserver(self,
                               selector: #selector(failedToPlayToEndTime(_:)),
                               name: .AVPlayerItemFailedToPlayToEndTime,
                               object: item)
        
        // KVO Observers
        // Player Status
        player.addObserver(self, forKeyPath: "rate", options: [.initial, .new, .old], context: nil)
        // AVPlayerItemStatusUnknown, AVPlayerItemStatusReadyToPlay, AVPlayerItemStatusFailed
        item.addObserver(self, forKeyPath: "status", options: [.new, .initial], context: nil)
        // 當前影片的進度緩衝
        item.addObserver(self, forKeyPath: "loadedTimeRanges", options: [.new, .initial], context: nil)
        // 緩衝區空的，需等待數據
        item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: [.new, .initial], context: nil)
        // 緩衝區有足夠的數據能播放
        item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: [.new, .initial], context: nil)
        
        item.addObserver(self, forKeyPath: "duration", options: [.new, .initial], context: nil)
    }
    
    private func removeObserversFrom(_ item: AVPlayerItem) {
        let notiCenter = NotificationCenter.default
        notiCenter.removeObserver(self,
                                  name: .AVPlayerItemDidPlayToEndTime,
                                  object: item)
        notiCenter.removeObserver(self,
                                  name: .AVPlayerItemFailedToPlayToEndTime,
                                  object: item)
        player.removeObserver(self, forKeyPath: "rate")
        item.removeObserver(self, forKeyPath: "status")
        item.removeObserver(self, forKeyPath: "loadedTimeRanges")
        item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        item.removeObserver(self, forKeyPath: "duration")
    }
    
    // MARK: - initialization and deallocation
    
    override public init() {
        self.player = AVPlayer()
        self.playerLayerView = MSSPlayerLayerView()
        self.playerLayerView.playerLayer.player = self.player
        super.init()
        setAllFunctionalViewsToContainerViews()
    }
    
    deinit {
        if let currentResourceItem = currentResource?.playerItem {
            removeObserversFrom(currentResourceItem)
        }
    }
    
    // MARK: - PlayerGestureViewDelegat
    open func gestureView(_ gestureView: PlayerGestureView, singleTapWith numberOfTouch: Int) {
        let controlView = getCurrentControlView()
        controlView.isShowing ? controlView.hideControlView(animated: true): controlView.showControlView(animated: true)
    }
    
    open func gestureView(_ gestureView: PlayerGestureView, doubleTapWith numberOfTouch: Int) {
        switch state {
        case .playing: pause()
        default: play()
        }
    }
    
    open func gestureView(_ gestureView: PlayerGestureView, state: UIGestureRecognizer.State, velocityPoint: CGPoint) {
        switch state {
        case .began:
            gestureChangeValue = 0.0
            switch gestureView.panDirection {
            case .vertical: break
            case .horizontal:
                isPlayingBeforeSeeking = isPlaying
                stopTimer()
            }
        case .changed:
            switch gestureView.panDirection {
            case .vertical:
                if gestureView.panStartLocation.x < gestureView.bounds.size.width / 2 {
                    // MARK: - change volume
                    let volumeController = PlayerSystemService.getVolumeController()
                    let adjustValue: CGFloat = 0.02
                    if velocityPoint.y > 0 {
                        volumeController.addVolume(Float(-adjustValue))
                    } else if velocityPoint.y < 0 {
                        volumeController.addVolume(Float(adjustValue))
                    } else {
                        return
                    }
                } else {
                    // MARK: - change brightness
                    let brightnessController = PlayerSystemService.getBrightnessController()
                    brightnessController.changeOrientation(UIDevice.current.orientation)
                    let adjustValue: CGFloat = 0.01
                    if velocityPoint.y > 0 {
                        brightnessController.addBrightness(-adjustValue)
                    } else if velocityPoint.y < 0 {
                        brightnessController.addBrightness(adjustValue)
                    } else {
                        return
                    }
                }
            case .horizontal:
                gestureChangeValue += velocityPoint.x
                guard let playerItem = player.currentItem else { return }
                // 防止出現NAN
                guard playerItem.duration.timescale != 0 else { return }
                let currentTime = TimeInterval(CMTimeGetSeconds(playerItem.currentTime()))
                let totalTime = TimeInterval(CMTimeGetSeconds(playerItem.duration))
                var seekRate = totalTime / 400
                // Modify seekRate
                if seekRate < 0.5 { seekRate = 0.5 }
                shouldSeekTo = currentTime + TimeInterval(gestureChangeValue) / 100 * seekRate
                // Modify shouldSeekTo value
                if shouldSeekTo >= totalTime {
                    shouldSeekTo = floor(totalTime)
                } else if shouldSeekTo <= 0 {
                    shouldSeekTo = 0
                }
                getCurrentControlView().showSeekTo(shouldSeekTo, total: totalTime, isAdd: shouldSeekTo > 0)
            }
        case .ended:
            switch gestureView.panDirection {
            case .vertical: break
            case .horizontal:
                getCurrentControlView().hideSeekView()
                activeTimer()
                switch self.state {
                case .playedToTheEnd, .buffering, .bufferFinished, .readyToPlay, .playing:
                    seek(to: shouldSeekTo) { [weak self](isFinished) in
                        guard let self = self else { return }
                        if isFinished {
                            if self.isPlayingBeforeSeeking {
                                self.play()
                            } else {
                                self.pause()
                            }
                        }
                    }
                case .pause:
                    seek(to: shouldSeekTo) { [weak self](isFinished) in
                        guard let self = self else { return }
                        if isFinished {
                            self.pause()
                        }
                    }
                case .empty, .error(_), .initial: break
                }
            }
        default: break
        }
    }

    // MARK: - PlayerCoontrolViewDelegate
    open func playerControlView(_ controlView: PlayerControlView, isPlaying: Bool) {
        isPlaying ? play(): pause()
    }
    
    open func playerControlView(_ controlView: PlayerControlView, isFullScreen: Bool) {
        changeToFullScreen(isFullScreen)
    }
    
    open func playerControlView(_ controlView: PlayerControlView, willAppear animated: Bool) {
        delegate?.playerController(self, controlView: controlView, willAppear: animated)
    }
    
    open func playerControlView(_ controlView: PlayerControlView, didAppear animated: Bool) {
        delegate?.playerController(self, controlView: controlView, didAppear: animated)
    }
    
    open func playerControlView(_ controlView: PlayerControlView, willDisappear animated: Bool) {
        delegate?.playerController(self, controlView: controlView, willDisappear: animated)
    }
    
    open func playerControlView(_ controlView: PlayerControlView, didDisappear animated: Bool) {
        delegate?.playerController(self, controlView: controlView, didDisappear: animated)
    }
    
    open func playerControlView(_ controlView: PlayerControlView, slider: UISlider, onSlider event: UIControl.Event) {
        switch event {
        case .touchDown:
            isSliderSliding = true
            isPlayingBeforeSeeking = isPlaying
            stopTimer()
        case .valueChanged:
            guard let playerItem = player.currentItem else { return }
            // 防止出現NAN
            guard playerItem.duration.timescale != 0 else { return }
            let totalTime = TimeInterval(CMTimeGetSeconds(playerItem.duration))
            let target = totalTime * Double(slider.value)
            getCurrentControlView().showSeekTo(target, total: totalTime, isAdd: target > 0)
        case .touchUpInside:
            // update controlView
            getCurrentControlView().hideSeekView()
            
            guard let playerItem = player.currentItem else { return }
            // 防止出現NAN
            guard playerItem.duration.timescale != 0 else { return }
            // 計算要移動的時間
            let totalTime = TimeInterval(CMTimeGetSeconds(playerItem.duration))
            let target = totalTime * Double(slider.value)
            shouldSeekTo = floor(target)
            // MARK: - 在這邊才恢復 timer，因為如果在前面恢復 timer 則 slider 的 value 會被更新導致計算會有問題
            activeTimer()
            isSliderSliding = false
            
            switch self.state {
            case .playedToTheEnd, .buffering, .bufferFinished, .readyToPlay, .playing:
                seek(to: shouldSeekTo) { [weak self](isFinished) in
                    guard let self = self else { return }
                    if isFinished {
                        if self.isPlayingBeforeSeeking {
                            self.play()
                        } else {
                            self.pause()
                        }
                        
                        if self.isSliderSliding {
                            self.stopTimer()
                        } else {
                            self.activeTimer()
                        }
                    }
                }
            case .pause:
                seek(to: shouldSeekTo) { [weak self](isFinished) in
                    guard let self = self else { return }
                    if isFinished {
                        self.pause()
                        if self.isSliderSliding {
                            self.stopTimer()
                        } else {
                            self.activeTimer()
                        }
                    }
                }
            case .empty, .error(_), .initial: break
            }
        default: break
        }
    }

    // MARK: - PlayerPauseViewDelegate
    open func pauseView(_ pauseView: PlayerPauseView, isPlay: Bool) {
        isPlay ? play(): pause()
    }

    // MARK: - PlayerPlayNextViewDelegate
    open func playNextView(_ playNextView: PlayerPlayNextView, didPlayNext playnext: Bool) {
        if playnext {
            changeResourceBy(index: currentResourceIndex + 1)
        }
    }
    
    open func playNextView(_ playNextView: PlayerPlayNextView, didCancel cancel: Bool) {
        
    }

    // MARK: - PlayerReplayViewDelegate
    open func playerReplayView(_ replayView: PlayerReplayView, didReplay replay: Bool) {
        if replay {
            seek(to: 0, completion: nil)
            play()
        }
    }
    
    open func playerReplayView(_ replayView: PlayerReplayView, didCancel cancel: Bool) {
        
    }

    // MARK: - PlayerPresenterDelegate
    open func playerPresenter(_ presenter: PlayerPresenter, orientationDidChanged orientation: UIDeviceOrientation) {
       //Update UI
        switch orientation {
        case .landscapeLeft, .landscapeRight:
            // 目前是否為全螢幕，若為 portrait 則代表目前不是全螢幕
            let isCurrentFullScreen = presenter.currentMode != .portrait
            // 先詢問是否能變更全螢幕狀態
            let shouldAllowChangeFullScreenState = delegate?.playerController(self,
                                                                              shouldAllowOrientationChangeFullScreenState: orientation,
                                                                              isCurrentFullScreen: isCurrentFullScreen)
            // 如果全螢幕是 portrait 則不需要旋轉的時候變更全螢幕狀態
            if !presenter.isPortraitFullScreen {
                switch (presenter.currentMode, orientation) {
                case (.landScapeRightFullScreen, .landscapeRight): break
                case (.landScapeLeftFullScreen, .landscapeLeft): break
                case (.landScapeRightFullScreen, .landscapeLeft), (.portrait, .landscapeLeft):
                    if (shouldAllowChangeFullScreenState ?? true) {
                        changeToFullScreen(true)
                        let volumeController = PlayerSystemService.getVolumeController()
                        volumeController.changeToFullScreenMode(true)
                        volumeController.setOnView(containerView)
                    }
                case (.landScapeLeftFullScreen, .landscapeRight), (.portrait, .landscapeRight):
                    if (shouldAllowChangeFullScreenState ?? true) {
                        changeToFullScreen(true)
                        let volumeController = PlayerSystemService.getVolumeController()
                        volumeController.changeToFullScreenMode(true)
                        volumeController.setOnView(containerView)
                    }
                default: break
                }
            }

        case .portrait:
            // 目前是否為全螢幕，若為 portrait 則代表目前不是全螢幕
            let isCurrentFullScreen = presenter.currentMode != .portrait
            // 先詢問是否能變更全螢幕狀態
            let shouldAllowChangeFullScreenState = delegate?.playerController(self,
                                                                              shouldAllowOrientationChangeFullScreenState: orientation,
                                                                              isCurrentFullScreen: isCurrentFullScreen)
            // 如果全螢幕是 portrait 則不需要旋轉的時候變更全螢幕狀態
            if !presenter.isPortraitFullScreen {
                if isCurrentFullScreen && (shouldAllowChangeFullScreenState ?? true) {
                    changeToFullScreen(false)
                    let volumeController = PlayerSystemService.getVolumeController()
                    volumeController.changeToFullScreenMode(false)
                }
            }
        default: break
        }
    }
    
    open func playerPresenter(_ presenter: PlayerPresenter, modeDidChanged mode: PresentMode) {
        delegate?.playerController(self, didChanged: mode)
    }
    
    open func playerPresenter(_ presenter: PlayerPresenter, modeWillChanged mode: PresentMode) {
        delegate?.playerController(self, willChanged: mode)
    }
}
