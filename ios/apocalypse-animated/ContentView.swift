//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI

enum ChapterItem: Decodable {
    case Verse(number: Int, text: String)
    case Animation(basename: String, width: Int, height: Int)
    
    enum CodingKeys: String, CodingKey {
        case type, text, basename, width, height, number
    }
    
    enum ItemType: String, Decodable {
        case verse, animation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ItemType.self, forKey: .type)
        
        switch type {
        case .verse:
            let number = try container.decode(Int.self, forKey: .number)
            let text = try container.decode(String.self, forKey: .text)
            self = .Verse(number: number, text: text)
        case .animation:
            let basename = try container.decode(String.self, forKey: .basename)
            let width = try container.decode(Int.self, forKey: .width)
            let height = try container.decode(Int.self, forKey: .height)
            self = .Animation(basename: basename, width: width, height: height)
        }
    }
}

func load<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

let Chapters: [Chapter] = load("content/chapters.json")

struct Chapter: Decodable {
    let title: String
    let description: String
    let items: [ChapterItem]
}

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
                LoopingVideo(video: self.video, shouldPlay: self.isVisible(geo))
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
        let containerWidth = min(self.containerGeometry.frame(in: .global).width, CGFloat(self.maxWidth))
        let height = (CGFloat(self.height) * containerWidth) / CGFloat(self.width)
        return (containerWidth, height)
    }
}

struct VerseView: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(String(self.number)).baselineOffset(4.0).padding([.top, .leading]).font(.system(size: 12.0))
            Text(self.text).padding().frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct VerseView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            VerseView(number: 1, text: "I am Alpha and Omega, the beginning and the ending, saith the Lord, which is, and which was, and which is to come, the Almighty.")
            VerseView(number: 2, text: "I am a tiny verse.")
        }
    }
}

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

struct PageButtons: View {
    @Binding var page: Int?
    let maxPage: Int
    
    var body: some View {
        HStack {
            Button("←") {
                if let page = self.page {
                    self.page = page - 1
                }
            }.disabled(self.page == 0)
            Button("→") {
                if let page = self.page {
                    self.page = page + 1
                }
            }.disabled(self.page == self.maxPage)
        }
    }
}

struct ContentView: View {
    @State private var currentChapter: Int? = nil
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Apocalypse Animated").font(.title).padding()
                    ForEach(0..<Chapters.count) { id in
                        let chapter = Chapters[id]
                        NavigationLink(destination: ChapterView(data: chapter).navigationBarItems(trailing: PageButtons(page: $currentChapter, maxPage: Chapters.count - 1)), tag: id, selection: $currentChapter) {
                            Text(chapter.title).padding([.top, .leading, .trailing])
                        }
                        Text(chapter.description).padding([.bottom]).foregroundColor(.gray)
                    }
                }.frame(maxWidth: .infinity)
            }
            // We're forcing a StackNavigationViewStyle because problems
            // occur on larger devices (plus-sized iPhones, iPads) if we don't.
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
