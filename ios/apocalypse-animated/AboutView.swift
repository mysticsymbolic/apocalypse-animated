//
//  AboutView.swift
//  apocalypse-animated
//
//  Created by Atul Varma on 2/27/22.
//

import SwiftUI

let content =
    """
    The [Book of Revelation](https://en.wikipedia.org/wiki/Book_of_Revelation) text used here is the [King James Version](https://en.wikipedia.org/wiki/King_James_Version) and is [Public Domain](https://en.wikipedia.org/wiki/Public_domain).

    The art and animation are by [Nina Paley](http://blog.ninapaley.com/), licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

    You do not need permission to copy, share, and re-use these Free Cultural works. Please attribute to “Nina Paley / apocalypseanimated.com”. If you would like to use this work in a proprietary project, such as a book or film, please [contact the artist](https://apocalypseanimated.com/wp-content/uploads/2022/02/nospam.jpg) to negotiate a waiver.

    Donations gladly accepted at [Paypal](https://www.paypal.com/donate/?hosted_button_id=U5LDCTZA4NGNN) or [Patreon](https://www.patreon.com/ninapaley).

    High-resolution uncompressed video of every animated loop on this web site can be downloaded at the [Internet Archive](https://archive.org/details/apocalypse-animated-clips-hd).

    This app was designed and engineered by [Atul Varma](https://portfolio.toolness.org/). Its source code is available under an MIT license on [GitHub](https://github.com/mysticsymbolic/apocalypse-animated).

    A web version of Apocalypse Animated is available at [apocalypseanimated.com](https://apocalypseanimated.com/).
    """

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("About Apocalypse Animated").font(.title2).padding([.bottom])
                // https://blog.eidinger.info/3-surprises-when-using-markdown-in-swiftui
                Text(.init(content))
            }.padding([.leading, .trailing])
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
