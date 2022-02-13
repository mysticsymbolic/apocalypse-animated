//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI
import AVKit

struct DetailView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Hello, worlde!")
                    .padding()
                Text("Hello, worlde2!")
                    .padding()
                MyPlayer(video: "throne2_5").frame(height: 300.0)
                Text("Hello, worlde3! I am a very very very long text snippet yup yup lorem ispum blah blah blah egpwoke gpwoekg pweogk wpegko apweog kpwaeokgapweogk awpoe gkapweo gkawepo gkawpeo kgapwokeg  apweogkap woekg paowke gpawoek gapweok gawpoe gkawpoe kgawpeo kgawpo gkawpeo kgapwoegk awpeg okawpe ogkawpe ogkawepo kgapweo kgapweo kapwoe kaagpeokg awegpo akwepgo kawpo egkawpeo kawpeo gkapweo kapwoe gkapweo kgapweo kpgaowe k")
                    .padding()
            }
        }
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
    
    let video: String
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        print("Update UI view...")
    }
    
    func makeUIView(context: Context) -> MyPlayerUIView {
        print("Creating UI view.")
        let myAsset: AVAsset = AVAsset(url: Bundle.main.url(forResource: "content/video/\(self.video)", withExtension: "mp4")!)
        let myPlayerItem = AVPlayerItem(asset: myAsset)
        
        return MyPlayerUIView(item: myPlayerItem)
    }
}

class MyPlayerUIView : UIView {
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
