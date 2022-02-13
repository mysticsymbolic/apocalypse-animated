//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI
import AVKit

struct DetailView: View {
    private let myPlayer: AVPlayer = AVPlayer(url: Bundle.main.url(forResource: "content/video/throne2_5", withExtension: "mp4")!)
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Hello, worlde!")
                    .padding()
                Text("Hello, worlde2!")
                    .padding()
                MyPlayer(player: myPlayer).frame(height: 300.0).onAppear(perform: {
                    self.startMyMovie()
                }).onDisappear(perform: {
                    self.stopMyMovie()
                })
                Text("Hello, worlde3! I am a very very very long text snippet yup yup lorem ispum blah blah blah egpwoke gpwoekg pweogk wpegko apweog kpwaeokgapweogk awpoe gkapweo gkawepo gkawpeo kgapwokeg  apweogkap woekg paowke gpawoek gapweok gawpoe gkawpoe kgawpeo kgawpo gkawpeo kgapwoegk awpeg okawpe ogkawpe ogkawepo kgapweo kgapweo kapwoe kaagpeokg awegpo akwepgo kawpo egkawpeo kawpeo gkapweo kapwoe gkapweo kgapweo kpgaowe k")
                    .padding()
            }
        }
    }
    
    private func startMyMovie() {
        print("Oooo starting movie.")
        self.myPlayer.seek(to: CMTime(seconds: 0.0, preferredTimescale: 600))
        self.myPlayer.play()
    }
    
    private func stopMyMovie() {
        print("Stopping movie.")
        self.myPlayer.pause()
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: DetailView()) {
                    Text("SUP")
                }
                NavigationLink(destination: Text("here is another view")) {
                    Text("Other")
                }
            }
        }
    }
}

struct MyPlayer : UIViewRepresentable {
    typealias UIViewType = MyPlayerUIView
    
    let player: AVPlayer
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print("Update UI view...")
    }
    
    func makeUIView(context: Context) -> MyPlayerUIView {
        print("Creating UI view.")
        return MyPlayerUIView(player: player)
    }
    
    static func dismantleUIView(_ uiView: MyPlayerUIView, coordinator: ()) {
        uiView.shutdown()
    }
}

class MyPlayerUIView : UIView {
    private let playerLayer = AVPlayerLayer()
    
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        layer.addSublayer(playerLayer)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onItemEndedPlaying(notification:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    @objc
    private func onItemEndedPlaying(notification: Notification) {
        let item = notification.object as? AVPlayerItem
        if item == self.playerLayer.player?.currentItem {
            self.playerLayer.player?.seek(to: CMTime(seconds: 0.0, preferredTimescale: 600))
            self.playerLayer.player?.play()
        }
        print("AVPlayerItemDidPlayToEndTime")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
    
    public func shutdown() {
        NotificationCenter.default.removeObserver(self)
        print("Shutdown!")
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
