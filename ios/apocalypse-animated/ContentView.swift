//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI

private struct PageButtons: View {
    @Binding var page: Int?
    let maxPage: Int
    
    var body: some View {
        HStack {
            Button("Previous") {
                if let page = self.page {
                    self.page = page - 1
                }
            }.disabled(self.page == 0)
            Button("Next") {
                if let page = self.page {
                    self.page = page + 1
                }
            }.disabled(self.page == self.maxPage)
        }
    }
}

struct ContentView: View {
    @State private var currentChapter: Int? = nil
    
    let chapters: [Chapter]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    Text("Apocalypse Animated").font(.title).padding()
                    ForEach(0..<self.chapters.count) { id in
                        let chapter = self.chapters[id]
                        NavigationLink(destination: ChapterView(data: chapter).navigationBarItems(trailing: PageButtons(page: $currentChapter, maxPage: self.chapters.count - 1)), tag: id, selection: $currentChapter) {
                            Text(chapter.title).padding([.top, .leading, .trailing])
                        }
                        Text(chapter.description).padding([.bottom]).foregroundColor(.gray)
                    }
                    NavigationLink(destination: AboutView()) {
                        Text("About Apocalypse Animated").padding()
                    }
                }.frame(maxWidth: .infinity)
            }
            // We're forcing a StackNavigationViewStyle because problems
            // occur on larger devices (plus-sized iPhones, iPads) if we don't.
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
