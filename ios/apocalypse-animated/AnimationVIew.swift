//
//  AnimationView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/14/22.
//

import SwiftUI
import AVKit

struct AnimationView: View {
    let video: String
    let width: Int
    let height: Int
    let containerGeometry: GeometryProxy
    let maxWidth: Double
    
    var body: some View {
        let (width, height) = self.getSize()
        GeometryReader { geo in
            // We're testing to see if the animation is *almost* visible,
            // which will help prevent any brief flickers where the movie is
            // still loading while it's on-screen.
            let isAlmostVisible = self.isVisible(geo, yDilation: 100.0)
            if isAlmostVisible {
                LoopingVideoView(video: self.video, shouldPlay: self.isVisible(geo))
            } else {
                EmptyView()
            }
        }.frame(width: width, height: height)
    }
    
    private func isVisible(_ geo: GeometryProxy, yDilation: Double = 0.0) -> Bool {
        let frame = geo.frame(in: .global).insetBy(dx: 0.0, dy: -yDilation)
        return frame.intersects(self.containerGeometry.frame(in: .global))
    }
    
    private func getSize() -> (CGFloat, CGFloat) {
        // This helps ensure that the animation actually
        // goes edge-to-edge, i.e. that we don't have tiny
        // subpixel slivers of empty space between the
        // animation and the edge of the screen.
        let EXTRA_WIDTH = 0.5
        
        let containerWidth = min(self.containerGeometry.frame(in: .global).width, CGFloat(self.maxWidth)) + EXTRA_WIDTH
        let height = (CGFloat(self.height) * containerWidth) / CGFloat(self.width)
        return (containerWidth, height)
    }
}

private struct LoopingVideoView : UIViewRepresentable {
    typealias UIViewType = LoopingVideoUIView
    
    let video: String
    let shouldPlay: Bool
    
    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) {
        uiView.setShouldPlay(self.shouldPlay)
    }
    
    func makeUIView(context: Context) -> LoopingVideoUIView {
        let myAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "content/video/\(self.video)", withExtension: "mp4")!)
        let myPlayerItem = AVPlayerItem(asset: myAsset)
        
        return LoopingVideoUIView(item: myPlayerItem, name: self.video, shouldPlay: self.shouldPlay)
    }
}

private class LoopingVideoUIView : UIView {
    private let name: String
    private let playerLayer = AVPlayerLayer()
    private let player: AVPlayer
    private var shouldPlay: Bool

    init(item: AVPlayerItem, name: String, shouldPlay: Bool) {
        self.name = name
        self.shouldPlay = shouldPlay
        player = AVPlayer(playerItem: item)
        super.init(frame: .zero)
        playerLayer.player = player

        if (self.shouldPlay) {
            player.play()
        }

        layer.addSublayer(playerLayer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidBecomeActive(application:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onItemEndedPlaying(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        let playState = self.shouldPlay ? "playing" : "paused"
        print("Creating LoopingVideoUIView '\(self.name)' (\(playState)).")
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
