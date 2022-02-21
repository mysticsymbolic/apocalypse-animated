//
//  LoopingVideo.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/14/22.
//

import SwiftUI
import AVKit

struct LoopingVideo : UIViewRepresentable {
    typealias UIViewType = LoopingVideoUIView
    
    let video: String
    let isVisible: Bool
    
    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) {
        uiView.setShouldPlay(self.isVisible)
    }
    
    func makeUIView(context: Context) -> LoopingVideoUIView {
        let myAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "content/video/\(self.video)", withExtension: "mp4")!)
        let myPlayerItem = AVPlayerItem(asset: myAsset)
        
        return LoopingVideoUIView(item: myPlayerItem, name: self.video)
    }
}

class LoopingVideoUIView : UIView {
    private let name: String
    private let playerLayer = AVPlayerLayer()
    private let player: AVPlayer
    private var shouldPlay: Bool = true

    init(item: AVPlayerItem, name: String) {
        self.name = name
        player = AVPlayer(playerItem: item)
        super.init(frame: .zero)
        playerLayer.player = player

        if (self.shouldPlay) {
            player.play()
        }

        layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidBecomeActive(application:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onItemEndedPlaying(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        print("Creating LoopingVideoUIView '\(self.name)'.")
    }

    func setShouldPlay(_ value: Bool) {
        if self.shouldPlay != value {
            self.shouldPlay = value
            if self.shouldPlay {
                print("Playing LoopingVideoUIView '\(self.name)'.")
                self.player.play()
            } else {
                print("Pausing LoopingVideoUIView '\(self.name)'.")
                self.player.pause()
            }
        }
    }

    @objc
    private func onApplicationDidBecomeActive(application: UIApplication) {
        if self.shouldPlay {
            print("Application became active, playing '\(self.name)'.")
            self.player.play()
        }
    }

    @objc
    private func onItemEndedPlaying(notification: Notification) {
        let item = notification.object as? AVPlayerItem
        if item == self.playerLayer.player?.currentItem {
            if self.shouldPlay {
                // Note that we used to use an AVPlayerLooper for this instead of doing
                // it manually, but that caused lots of blank frames for very short
                // videos that were less than a second long, so now we're doing it
                // manually.
                self.playerLayer.player?.seek(to: CMTime(seconds: 0.0, preferredTimescale: 600))
                self.playerLayer.player?.play()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("Destroying LoopingVideoUIView '\(self.name)'.")
    }
}
