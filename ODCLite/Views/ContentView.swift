//
//  This source file is part of the ODCLite open source project
//
//  Copyright (c) 2024 Erik Basargin
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("ODC Lite", systemImage: "hat.widebrim.fill")
                
                Spacer()
                
                Button {
                    // Start/stop stream
                } label: {
                    Image(systemName: "record.circle")
                }
                .buttonStyle(.borderless)
            }
            .font(.title)
            .padding()
            
            Divider()
            
            Form {
                Section("Video") {
                    Toggle("Exclude app from stream", isOn: .constant(true))
                    Toggle("Recorde stream", isOn: .constant(true))
                }
                
                Section("Audio") {
                    Toggle("Capture system audio", isOn: .constant(true))
                    Toggle("Exclude app audio", isOn: .constant(true))
                }
                
                Section("Twitch") {
                    SecureField("Primary Stream key", text: .constant(""))
                }
            }
            .formStyle(ContentFormStyle())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.horizontal, .bottom])
            .background(Color.secondary.quaternary)
        }
    }
}

private struct ContentFormStyle: FormStyle {
    func makeBody(configuration: Configuration) -> some View {
        ForEach(sections: configuration.content) { section in
            VStack(alignment: .leading) {
                section.header
                    .font(.title3)
                    .padding(.top, 8)
                
                section.content
                
                section.footer
            }
        }
    }
}

#Preview {
    ContentView()
}
