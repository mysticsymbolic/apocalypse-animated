//
//  Chapter.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/27/22.
//

import Foundation

enum ChapterItem: Decodable {
    case Verse(number: Int?, text: String)
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
            let number = try container.decode(Int?.self, forKey: .number)
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

struct Chapter: Decodable {
    let title: String
    let description: String
    let items: [ChapterItem]
}
