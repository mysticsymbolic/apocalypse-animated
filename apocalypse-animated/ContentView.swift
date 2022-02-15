//
//  ContentView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/13/22.
//

import SwiftUI

struct DetailView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("Here is some text!")
                    .padding()
                Text("Here is some more text!")
                    .padding()
                LoopingVideo(video: "throne2_5").frame(height: 300.0)
                Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque molestie diam dapibus ullamcorper fringilla. Nunc nulla purus, consequat non rutrum sed, rhoncus eu nunc. Curabitur eleifend leo vitae convallis bibendum. Curabitur et ligula nec purus ornare lacinia nec convallis dolor. Vivamus augue nibh, molestie id viverra in, fermentum vel turpis. Nam a neque lacus. Suspendisse eu tortor est. Ut eget tellus pellentesque, dapibus leo ut, dapibus elit. Aliquam interdum molestie lorem. Nullam semper imperdiet orci.")
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
