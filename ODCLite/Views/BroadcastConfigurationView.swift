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

struct BroadcastConfigurationView: View {

    @Environment(BroadcastManager.self) private var broadcastManager

    var body: some View {
        @Bindable var broadcastManager = broadcastManager

        Form {
            Section("Video") {
                Toggle("Exclude app from stream", isOn: $broadcastManager.excludeAppFromStream)
            }

            Section("Audio") {
                Toggle("Capture system audio", isOn: $broadcastManager.captureSystemAudio)
                Toggle("Exclude app audio", isOn: $broadcastManager.excludeAppAudio)
                Toggle("Capture microphone", isOn: $broadcastManager.captureMicrophone)
            }

            Section("Twitch") {
                SecureField("Primary Stream key", text: $broadcastManager.primaryStreamKey)
            }
        }
        .formStyle(ContentFormStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.horizontal, .bottom])
        .background(Color.secondary.quaternary)
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
    BroadcastConfigurationView()
        .environment(BroadcastManager())
}
