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
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print("Update UI view...")
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
    private let looper: NSObject
    
    init(item: AVPlayerItem) {
        let myPlayer = AVQueuePlayer(playerItem: item)
        looper = AVPlayerLooper(player: myPlayer, templateItem: item)
        super.init(frame: .zero)
        
        playerLayer.player = myPlayer
        
        layer.addSublayer(playerLayer)
        
        myPlayer.play()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}


struct LoopingVideo_Previews: PreviewProvider {
    static var previews: some View {
        LoopingVideo(video: "throne2_5").frame(height: 300)
    }
}
