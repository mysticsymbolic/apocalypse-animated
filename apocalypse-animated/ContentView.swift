//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI

enum ChapterItem: Decodable, Hashable {
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

let SampleChapters: [Chapter] = load("content/sample-chapters.json")

struct Chapter: Decodable, Hashable {
    let title: String
    let items: [ChapterItem]
}

struct ChapterView: View {
    let data: Chapter
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(self.data.items, id: \.self) { item in
                    switch item {
                    case .Verse(let number, let text):
                        Text("\(number). \(text)").padding()
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
                ForEach(SampleChapters, id: \.self) { chapter in
                    NavigationLink(destination: ChapterView(data: chapter)) {
                        Text(chapter.title).padding()
                    }
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
