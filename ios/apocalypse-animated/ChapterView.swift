//
//  ChapterView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/27/22.
//

import SwiftUI

struct ChapterView: View {
    let data: Chapter
    
    var body: some View {
        let maxWidth = 640.0
        GeometryReader { geo in
            ScrollView {
                HStack {
                    if geo.size.width > maxWidth {
                        Spacer()
                    }
                    VStack {
                        Text(self.data.title).font(.title2).padding()
                        ForEach(0..<self.data.items.count) { id in
                            let item = self.data.items[id]
                            switch item {
                            case .Verse(let number, let text):
                                VerseView(number: number, text: text)
                            case .Animation(let basename, let width, let height):
                                AnimationView(video: basename, width: width, height: height, containerGeometry: geo, maxWidth: maxWidth)
                            }
                        }
                    }.frame(maxWidth: maxWidth)
                    if geo.size.width > maxWidth {
                        Spacer()
                    }
                }
            }
        }
    }
}

private struct VerseView: View {
    let number: Int?
    let text: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(self.getNumberStr()).baselineOffset(4.0).padding([.top, .leading]).font(.system(size: 12.0))
            Text(self.text).padding().frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func getNumberStr() -> String {
        if let number = self.number {
            return String(number)
        }
        return ""
    }
}

struct VerseView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VerseView(number: 1, text: "I am Alpha and Omega, the beginning and the ending, saith the Lord, which is, and which was, and which is to come, the Almighty.")
            VerseView(number: 2, text: "I am a tiny verse.")
            VerseView(number: nil, text: "I am a continuation of the last verse.")
        }
    }
}
