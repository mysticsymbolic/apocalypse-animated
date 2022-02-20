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
        print("Update UI view... \(self.video) \(self.isVisible)")
    }
    
    func makeUIView(context: Context) -> LoopingVideoUIView {
        print("Creating UI view.")
        let myAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "content/video/\(self.video)", withExtension: "mp4")!)
        let myPlayerItem = AVPlayerItem(asset: myAsset)
        
        return LoopingVideoUIView(item: myPlayerItem)
    }
}

class LoopingVideoUIView : UIView {
    private let playerLayer = AVPlayerLayer()
    private let player: AVQueuePlayer
    private let looper: NSObject
    private var shouldPlay: Bool = false

    init(item: AVPlayerItem) {
        player = AVQueuePlayer(playerItem: item)
        looper = AVPlayerLooper(player: player, templateItem: item)
        super.init(frame: .zero)
        playerLayer.player = player
        
        layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidBecomeActive(application:)), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    func setShouldPlay(_ value: Bool) {
        if self.shouldPlay != value {
            self.shouldPlay = value
            if self.shouldPlay {
                self.player.play()
            } else {
                self.player.pause()
            }
        }
    }

    @objc
    private func onApplicationDidBecomeActive(application: UIApplication) {
        if self.shouldPlay {
            self.player.play()
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
    }
}
