//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI

enum ChapterItem: Decodable, Hashable {
    case Verse(text: String)
    case Animation(basename: String, width: Int, height: Int)
    
    enum CodingKeys: String, CodingKey {
        case type, text, basename, width, height
    }
    
    enum ItemType: String, Decodable {
        case verse, animation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        
        switch type {
        case .verse:
            let text = try container.decode(String.self, forKey: .text)
            self = .Verse(text: text)
        case .animation:
            let basename = try container.decode(String.self, forKey: .basename)
            let width = try container.decode(Int.self, forKey: .width)
            let height = try container.decode(Int.self, forKey: .height)
            self = .Animation(basename: basename, width: width, height: height)
        }
    }
}

struct Chapter: Decodable, Hashable {
    let title: String
    let items: [ChapterItem]
}

let SampleChapter = Chapter(title: "Sample Chapter", items: [
    ChapterItem.Verse(text: "Here is some text! Yup."),
    ChapterItem.Verse(text: "Here is some more text!"),
    ChapterItem.Animation(basename: "throne2_5", width: 640, height: 360),
    ChapterItem.Verse(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque molestie diam dapibus ullamcorper fringilla. Nunc nulla purus, consequat non rutrum sed, rhoncus eu nunc. Curabitur eleifend leo vitae convallis bibendum. Curabitur et ligula nec purus ornare lacinia nec convallis dolor. Vivamus augue nibh, molestie id viverra in, fermentum vel turpis. Nam a neque lacus. Suspendisse eu tortor est. Ut eget tellus pellentesque, dapibus leo ut, dapibus elit. Aliquam interdum molestie lorem. Nullam semper imperdiet orci.")
])

struct ChapterView: View {
    let data: Chapter
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(self.data.items, id: \.self) { item in
                    switch item {
                    case .Verse(let text):
                        Text(text).padding()
                    case .Animation(let basename, _, let height):
                        LoopingVideo(video: basename).frame(height: CGFloat(height))
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: ChapterView(data: SampleChapter)) {
                    Text("First view")
                }
                NavigationLink(destination: Text("here is another view")) {
                    Text("Second view")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
