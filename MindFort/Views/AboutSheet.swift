//
//  SettingsAcknowledgementsView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-05-29.
//

import SwiftUI


struct AboutSheet: View {
    var body: some View {
        ScrollView {
            // Warning: a view can only have 10 direct child views
            // We make a bunch of unnecessary Group views in here to work around this
            VStack(alignment: .leading) {
                Group {
                    Text("About MindFort")
                        .font(.title)
                        .bold()
                        .padding()
                    Text("MindFort is an app designed to help you remember passwords, especially passwords that you must not forget, like for your password database, GPG key, or Monero wallet.")
                        .lineLimit(nil)
                        .padding([.top, .bottom])
                    Text("It quizzes you in increasing intervals, a method known as spaced repetition that works well for memorizing facts in other contexts, like technical terms or foreign language vocabulary.")
                        .lineLimit(nil)
                        .padding([.top, .bottom])
                    Spacer()
                }
                
                Group {
                    Text("About spaced repetition")
                        .font(.title)
                        .bold()
                        .padding()
                    Text(try! AttributedString(markdown: """
                                       Per [Wikipedia](https://en.wikipedia.org/wiki/Spaced_repetition), "Spaced repetition is an evidence-based learning technique that is usually performed with flashcards. Newly introduced and more difficult flashcards are shown more frequently, while older and less difficult flashcards are shown less frequently in order to exploit the psychological spacing effect. The use of spaced repetition has been proven to increase the rate of learning."
                                       """))
                    .lineLimit(nil)
                    .padding([.top, .bottom])
                    Spacer()
                }
                
                Group {
                    Text("Inspiration")
                        .font(.title)
                        .bold()
                        .padding()
                    Text(try! AttributedString(markdown: """
                Thanks to Glyph for making [PINPal](https://github.com/glyph/PINPal), a command-line program written in Python designed to help you remember passwords via spaced repetition. I thought that was such a good idea that I wanted to make a mobile app that does the same thing.
                """))
                    .lineLimit(nil)
                    .padding([.top, .bottom])
                    Spacer()
                }
                
                Group {
                    Text("Acknowledgements")
                        .font(.title)
                        .bold()
                        .padding()
                    Text(try! AttributedString(markdown: """
                Thanks to Twitter for their excellent [Twemoji](https://blog.glyph.im/2023/04/post-pycon-us-2023-notes.html) open source emoji graphics, which I have used in this and many other projects.
                    .linelimit(nil)
                """))
                    .lineLimit(nil)
                    .padding([.top, .bottom])
                }
                
            }.padding()
        }
    }
}

struct SettingsAcknowledgementsView_Previews: PreviewProvider {
    static var previews: some View {
        AboutSheet()
    }
}
